//
//  Repository+Pull.swift
//  SwiftGit2-OSX
//
//  Created by loki on 15.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

//#if DEBUG
//let checkoutStrategy      : CheckoutStrategy = .Safe
//let checkoutStrategyMerge : CheckoutStrategy = [.Safe, .AllowConflicts, .ConflictStyleMerge, .ConflictStyleDiff3]
//#else
nonisolated(unsafe) let checkoutStrategy      : CheckoutStrategy = .Force
nonisolated(unsafe) let checkoutStrategyMerge : CheckoutStrategy = [.Force, .AllowConflicts, .ConflictStyleMerge, .ConflictStyleDiff3]

//#endif

public enum MergeResult {
    case upToDate
    case fastForward
    case threeWaySuccess
    case threeWayConflict(Index)
}

public struct PullOptions {
    public var signature : Signature
    public var fetch : FetchOptions
    public var checkoutProgress: CheckoutProgressBlock?    = nil
    public var mergeOptions : MergeOptions                 = MergeOptions()
    
    public init(signature: Signature, fetch: FetchOptions) {
        self.signature = signature
        self.fetch     = fetch
    }
}

public extension Repository {    
    func pull(refspec: [String], _ target: BranchTarget, options: PullOptions, stashing: Bool = false) -> Result<MergeResult, Error> {
        return combine(fetch(refspec: refspec, target, options: options.fetch), mergeAnalysisUpstream(target))
            .flatMap { branch, anal in
                self.mergeFromUpstream(anal: anal, ourLocal: branch, options: options, stashing: stashing)
            }
    }
    
    private func mergeFromUpstream(anal: MergeAnalysis, ourLocal: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        guard !anal.contains(.upToDate) else { return .success(.upToDate) }
        
        let theirReference = ourLocal
            .upstream()
        
        if anal.contains(.fastForward) || anal.contains(.unborn) {
            /////////////////////////////////////
            // FAST-FORWARD MERGE
            
            return theirReference | { self.mergeFastForward(our: ourLocal, their: $0, options: options,
                                                            stashing: stashing) }
        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            
            return theirReference | { mergeThreeWay(our: ourLocal, their: $0, options: options,
                                                    stashing: stashing) }
        }

        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }

    private func mergeFastForward(our: Branch, their: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        let targetOID = their.target_resut
        
        let message = "pull: Fast-forward \(their.nameAsReferenceCleaned) -> \(our.nameAsReferenceCleaned)"
        
        return GitStasher(repo: self).wrap(skip: !stashing) {
            targetOID
                | { oid in our.set(target: oid, message: message) }
                | { $0.asBranch() }
                | { self.checkout(branch: $0, strategy: checkoutStrategy, progress: options.checkoutProgress, stashing: false) }
                | { _ in MergeResult.fastForward }
        }
    }
    
    private func mergeThreeWay(our: Branch, their: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        let repo = self
        let ourOID   = our.target_resut
        let theirOID = our.upstream()            | { $0.target_resut }
        let baseOID  = combine(ourOID, theirOID) | { self.mergeBase(one: $0, two: $1) }
        
        let message = baseOID
            | { base in "Merge \(their.nameAsReferenceCleaned) -> \(our.nameAsReferenceCleaned) | Base: \(base)" }
        
        let ourCommit   = ourOID   | { self.commit(oid: $0) }
        let theirCommit = theirOID | { self.commit(oid: $0) }
        
        let parents = combine(ourCommit, theirCommit) | { [$0, $1] }
        
        let branchName = our.nameAsReference
        
        let stasher: R<GitStasher>
        if stashing {
            stasher = GitStasher.init(repo: self, state: .tag("pull-merge")).push()
        } else {
            stasher = .success(.init(repo: self, state: .empty))
        }
        
        if case .failure(let error) = stasher {
            return .failure(error)
        }
        
        return [ourOID, theirOID, baseOID]
            .flatMap { $0.tree(self) }
            .flatMap { self.merge(our: $0[0], their: $0[1], ancestor: $0[2], options: options.mergeOptions) } // -> Index
            .if(\.hasConflicts,
                then: { index in
                    parents
                        .map {
                            // MERGE_HEAD creation
                            let _ = RevFile( repo: repo, type: .PullMsg)?
                                .generatePullMsg(from: index, msg: nil)
                                .save()

                            // MERGE_MODE creation
                            let _ = RevFile(repo: repo, type: .MergeMode )?
                                .save()

                            // MERGE_HEAD creation
                            OidRevFile( repo: repo, type: .MergeHead)?
                                .setOid(from: $0[1] )
                                .save()
                            
                            return
                        }//.flatMap { _ in GitStasher(repo: self, state: .tag("merge")).push() }
                         .flatMap { _ in self.checkout(index: index, strategy: checkoutStrategyMerge , progress: options.checkoutProgress) }
                         .map { _ in .threeWayConflict(index) }
                },
                else: { index in
                    combine(message, parents)
                        | { index.commit(into: self, signature: options.signature, message: $0, parents: $1) }
                        | { _ in self.checkout(ref: branchName, strategy: checkoutStrategy, progress: options.checkoutProgress, stashing: false) }
                        | { _ in stasher | { $0.pop() } }
                        | { _ in .threeWaySuccess }
                })
    }
}

private extension Result where Success == OID, Failure == Error {
    func tree(_ repo: Repository) -> Result<Tree, Error> {
        self | { repo.commit(oid: $0) } | { $0.tree() }
    }
}

public extension Index {
    func commit(into repo: Repository, signature: Signature, message: String, parents: [Commit]) -> Result<Void, Error> {
        writeTree(to: repo)
            | { tree in repo.commitCreate(signature: signature, message: message, tree: tree, parents: parents) }
            | { _ in () }
    }
}

extension MergeResult: Equatable {
    public var hasConflict: Bool {
        if case .threeWayConflict = self {
            return true
        } else {
            return false
        }
    }
    
    public static func == (lhs: MergeResult, rhs: MergeResult) -> Bool {
        switch (lhs, rhs) {
        case (.upToDate, .upToDate): return true
        case (.fastForward, .fastForward): return true
        case (.threeWaySuccess, .threeWaySuccess): return true
        default:
            return false
        }
    }
}
