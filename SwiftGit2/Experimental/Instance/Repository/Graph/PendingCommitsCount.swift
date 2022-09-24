//
//  PendingCommitsCount.swift
//  SwiftGit2-OSX
//
//  Created by loki on 05.07.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public enum PendingCommitsCount {
    case pushpull(Int,Int)
    case publish_pending(Int)          // no upastream
    case undefined
}

public extension Repository {
    func pendingCommitsCount(_ target: BranchTarget) -> R<PendingCommitsCount> {
        self.remoteNameList()
            .map { $0.isEmpty }
            .if(\.self, then: { _ in
                .success(.undefined)
            }, else: { _ in
                self._pendingCommitsCount(target)
            })
    }
    
    private func _pendingCommitsCount(_ target: BranchTarget) -> R<PendingCommitsCount> {
        if headIsDetached {
            return .success(.undefined)
        }
         
        //if self.remoteNameList()
        
        return upstreamExistsFor(target)
            .if(\.self, then: { _ in
                _pendingCommitsCount(target)
                    .map { PendingCommitsCount.pushpull($0, $1) }
            }, else: { _ in
                self.branches(.remote).flatMap { _pendingCommits(remoteBranches: $0, target: target) }
            })
    }
    
    func _pendingCommits(remoteBranches branches : [Branch], target: BranchTarget) -> R<PendingCommitsCount> {
        let names = branches.compactMap { $0.nameAsBranch }
        if names.isEmpty {
            return pendingCommitsOIDs(target, .push) | { $0.count } | { .publish_pending($0) }
        }
        
        let local = target.branch(in: self) | { $0.targetOID }
        let upstream = branches.findMainBranch().flatMap { $0.targetOID }
        //
        return combine(local,upstream)
            .flatMap { graphAheadBehind(local: $0, upstream: $1) }
            .map { ahead, behind in .publish_pending(ahead) }
    }

    func _pendingCommitsCount(_ target: BranchTarget) -> R<(Int,Int)> {
        let push = pendingCommitsOIDs(target, .push)    | { $0.count }
        let fetch = pendingCommitsOIDs(target, .fetch)  | { $0.count }
        
        return combine(push, fetch)
    }
}

internal extension Array where Element == Branch {
    func findMainBranch() -> R<Branch> {
        for item in self {
            if item.nameAsBranch == "origin/main" {
                print("findMainBranch(): main")
                return .success(item)
            }
            
            if item.nameAsBranch == "origin/master" {
                print("findMainBranch(): master")
                return .success(item)
            }
        }
        
        if let item = self.first {
            print("findMainBranch(): \(item.nameAsBranch ?? "error")")
            return .success(item)
        }
        return .failure(WTF("findMainBranch(): array is empty"))
    }
}


extension PendingCommitsCount: Equatable {
    public static func == (lhs: PendingCommitsCount, rhs: PendingCommitsCount) -> Bool {
        switch (lhs, rhs) {
        case (.undefined, .undefined): return true
        case let (.publish_pending(lp), .publish_pending(rp)): return lp == rp
        case let (.pushpull(lpush,lpull), .pushpull(rpush, rpull)): return lpush == rpush && lpull == rpull
        default:
            return false
        }
    }
}
