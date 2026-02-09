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
    public var checkoutProgress: CheckoutProgressBlock?
    public var mergeOptions : MergeOptions
    
    public init(signature: Signature, fetch: FetchOptions, checkoutProgress: CheckoutProgressBlock? = nil, mergeOptions: MergeOptions = MergeOptions()) {
        self.signature = signature
        self.fetch     = fetch
        self.checkoutProgress = nil
        self.mergeOptions = mergeOptions
    }
}

public extension Repository {    
    func pull(refspec: [String], _ target: BranchTarget, options: PullOptions, stashing: Bool = false, merge3way: MergeThreeWay = .cli) -> Result<MergeResult, Error> {
        return combine(fetch(refspec: refspec, target, options: options.fetch), mergeAnalysisUpstream(target))
            .flatMap { branch, anal in
                return self.mergeFromUpstream(anal: anal, ourLocal: branch, options: options, stashing: stashing, merge3way: merge3way)
            }
    }
    
    private func mergeFromUpstream(anal: MergeAnalysis, ourLocal: Branch, options: PullOptions, stashing: Bool, merge3way: MergeThreeWay) -> R<MergeResult> {
        guard !anal.contains(.upToDate) else { return .success(.upToDate) }
        
        let theirReference = ourLocal
            .upstream()
        
        if anal.contains(.fastForward) || anal.contains(.unborn) {
            //
            // FAST-FORWARD MERGE
            //
            
            return theirReference | { self.mergeFastForward(our: ourLocal, their: $0, options: options,
                                                            stashing: stashing) }
        } else if anal.contains(.normal) {
            //
            // THREE-WAY MERGE
            //
            
//            ourLocal
            //git  feature
            return theirReference | { their -> R<MergeResult> in
                switch merge3way {
                case .cli:
                    return mergeThreeWayCli(our: ourLocal, their: their, options: options, stashing: stashing)
                case .swiftGit2:
                    // works bad
                    return mergeThreeWay(our: ourLocal, their: their, options: options, stashing: stashing)
                }
            }
        }
        
        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }

    private func mergeFastForward(our: Branch, their: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        let targetOID = their.target_result
        
        let message = "pull: Fast-forward \(their.nameAsReferenceCleaned) -> \(our.nameAsReferenceCleaned)"
        
        return GitStasher(repo: self).wrap(skip: !stashing) {
            targetOID
                | { oid in our.set(target: oid, message: message) }
                | { $0.asBranch() }
                | { self.checkout(branch: $0, strategy: checkoutStrategy, progress: options.checkoutProgress, stashing: false) }
                | { _ in MergeResult.fastForward }
        }
    }
    
    
    
    private func mergeThreeWayCli(our: Branch, their: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        let theirName = their.nameAsReference
        
        // CLI already generate message for merge, so no need to create it here with code
        
        let stasher: R<GitStasher>
        if stashing {
            stasher = GitStasher.init(repo: self, state: .tag("pull-merge")).push()
        } else {
            stasher = .success(.init(repo: self, state: .empty))
        }
        
        if case .failure(let error) = stasher {
            return .failure(error)
        }
        
        let successStrs = ["recursive","ort","octopus","resolve","ours"].map{ "made by the '\($0)' strategy"}
        
        return combine(self.repoID.flatMap{ $0.HEAD }.flatMap{ $0.asOID }, our.target_result)
            .flatMap{ (headOID,ourOID) -> R<()> in
                if headOID != ourOID {
                    return self.repoID
                        .flatMap{ $0.repo }
                        .flatMap{ repo in
                            repo.checkout(ourOID, options: .init())
                                .flatMap { _ in repo.detachedHeadFix() }
                                .map{ _ in () }
                        }
                } else {
                    return .success(())
                }
            }
            .flatMap{ self.repoID }
            .flatMap{ repoID in
                XR.Shell.Git(repoID: repoID )
                    .run(args: ["merge", theirName])
            }
            .flatMap { str -> R<MergeResult> in
                if str.contains("Automatic merge failed") { // must be first
                    return self.index().map {
                        MergeResult.threeWayConflict($0)
                    }
                } else if str.contains("Already up to date") {
                    return .success(MergeResult.upToDate)
                } else if str.contains("Fast-forward") {
                    return .success(MergeResult.fastForward)
                } else if str.contains(oneOf: successStrs) {
                    // possibly last is best, but must be after "failed" at least
                    return .success(MergeResult.threeWaySuccess)
                }
                
                return .failure(WTF(str))
            }
            .flatMap { mergeResult in
                return stasher
                    .map { $0.pop() }
                    .map{ _ in mergeResult }
            }
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


public enum MergeThreeWay {
    case swiftGit2
    case cli
}


//
// DEPRECATED
//
fileprivate extension Repository {
    @available(*, deprecated, message: "Works bad. Check test_shouldResolveConflictAdvanced_File_Our or test_shouldResolveConflictAdvanced_File_Their")
    private func mergeThreeWay(our: Branch, their: Branch, options: PullOptions, stashing: Bool) -> R<MergeResult> {
        let repo = self
        let ourOID   = our.target_result
        let theirOID = our.upstream()            | { $0.target_result }
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
