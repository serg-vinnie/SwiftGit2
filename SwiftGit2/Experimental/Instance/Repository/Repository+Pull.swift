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

public enum MergeResult {
    case upToDate
    case fastForward
    case threeWaySuccess
    case threeWayConflict(Index)
}

public extension Repository {    
    func pull(_ target: BranchTarget, options: FetchOptions = FetchOptions(auth: .auto), signature: Signature) -> Result<MergeResult, Error> {
        return combine(fetch(target, options: options), mergeAnalysisUpstream(target))
            | { branch, anal in self.mergeFromUpstream(anal: anal, ourLocal: branch, signature: signature) }
    }

    private func mergeFromUpstream(anal: MergeAnalysis, ourLocal: Branch, signature: Signature) -> Result<MergeResult, Error> {
        guard !anal.contains(.upToDate) else { return .success(.upToDate) }
        
        let repo = self
        
        let theirReference = ourLocal
            .upstream()
        
        if anal.contains(.fastForward) || anal.contains(.unborn) {
            /////////////////////////////////////
            // FAST-FORWARD MERGE
            /////////////////////////////////////
            
            let targetOID = theirReference
                .flatMap { $0.targetOID }
            
            let message = theirReference.map { their in "Fast Forward MERGE \(their.nameAsReferenceCleaned) -> \(ourLocal.nameAsReferenceCleaned)" }
            
            return combine(targetOID, message)
                | { oid, message in ourLocal.set(target: oid, message: message) }
                | { $0.asBranch() }
                | { self.checkout(branch: $0, strategy: .Force) }
                | { _ in .fastForward }
            
        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            /////////////////////////////////
            
            let ourOID   = ourLocal.targetOID
            let theirOID = ourLocal.upstream()       | { $0.targetOID }
            let baseOID  = combine(ourOID, theirOID) | { self.mergeBase(one: $0, two: $1) }
            
            let message = combine(theirReference, baseOID)
                | { their, base in "MERGE [\(their.nameAsReferenceCleaned)] & [\(ourLocal.nameAsReferenceCleaned)] | BASE: \(base)" }
            
            let ourCommit   = ourOID   | { self.commit(oid: $0) }
            let theirCommit = theirOID | { self.commit(oid: $0) }
            
            let parents = combine(ourCommit, theirCommit) | { [$0, $1] }
            
            let branchName = ourLocal.nameAsReference
            
            return [ourOID, theirOID, baseOID]
                .flatMap { $0.tree(self) }
                .flatMap { self.merge(our: $0[0], their: $0[1], ancestor: $0[2]) } // -> Index
                .if(\.hasConflicts,
                    then: { index in
                        parents
                            .map {
                                // MERGE_HEAD creation
                                let _ = RevFile( repo: repo, type: .PullMsg)?
                                    .generatePullMsg(from: index)
                                    .save()
                                
                                // MERGE_HEAD creation
                                OidRevFile( repo: repo, type: .MergeHead)?
                                    .setOid(from: $0[1] )
                                    .save()
                            } | { _ in
                                repo.checkout(index: index, strategy: [.Force, .AllowConflicts, .ConflictStyleMerge, .ConflictStyleDiff3])
                                    | { _ in .success(.threeWayConflict(index)) }
                            }
                    },
                    else: { index in
                        combine(message, parents)
                            | { index.commit(into: self, signature: signature, message: $0, parents: $1) }
                            | { _ in self.checkout(branch: branchName, strategy: .Force) }
                            | { _ in .threeWaySuccess }
                    })
        }

        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }
}

private extension Result where Success == OID, Failure == Error {
    func tree(_ repo: Repository) -> Result<Tree, Error> {
        self | { repo.commit(oid: $0) } | { $0.tree() }
    }
}

internal extension Index {
    func commit(into repo: Repository, signature: Signature, message: String, parents: [Commit]) -> Result<Void, Error> {
        writeTree(to: repo)
            | { tree in repo.commitCreate(signature: signature, message: message, tree: tree, parents: parents) }
            | { _ in () }
    }
}

extension MergeResult: Equatable {
    var hasConflict: Bool {
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
