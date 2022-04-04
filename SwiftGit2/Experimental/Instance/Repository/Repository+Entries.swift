//
//  Repository+Entries.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 15.11.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

extension Repository {
   public func entries(target: CommitTarget, statusOptions: StatusOptions = StatusOptions(), findOptions: Diff.FindOptions = [.renames, .renamesFromRewrites] ) -> R<Entries> {
       return self.statusConflictSafe(options: statusOptions)
           .flatMap { status -> R<Entries> in
               if self.headIsUnborn {
                   return .success(.headIsUnborn)
               }
               
               if status.isEmpty == false {
                   return .success(.status(status))
               }
               
               // self.headIsUnborn == false
               return self.deltas(target: target, findOptions: findOptions)
                  .map { .commit($0) } as R<Entries>
            }
        }
}

public extension Repository {
    func deltas(target: CommitTarget, findOptions: Diff.FindOptions = [.renames, .renamesFromRewrites] ) -> R<CommitDetails> {
        if headIsUnborn {
            return .success(CommitDetails(parents: [], deltasWithHunks: [], all: [:], desc: ""))
        }
        
        let commit      = target.commit(in: self)
        let desc        = commit | { $0.description }
        let commitTree  = commit | { $0.tree() }
        let parents     = commit | { $0.parents() }
        
        if case .success(let parents) = parents {
            if parents.isEmpty {
                let deltas = commitTree | { self.diffTreeToTree(oldTree: nil, newTree: $0) } | { $0.asDeltasWithHunks() }
                
                return combine(deltas, desc) | { CommitDetails(parents: [], deltasWithHunks: $0, all: [:], desc: $1) }
            }
        }
        
        let parentOIDs  = parents | { $0 | { $0.oid } }
        let parentTrees = parents | { $0 | { $0.tree() } }
        let deltas      = combine(commitTree, parentTrees) | { tree, parents in parents | {
            self.diffTreeToTree(oldTree: $0, newTree: tree)
                | { $0.findSimilar(options: findOptions) }
                | { $0.asDeltasWithHunks() } } }
        
        return combine(parentOIDs, deltas, desc) | { commitDetails(parents: $0, deltas: $1, desc: $2) }
    }
    
    func commitDetails(parents: [OID], deltas:[[Diff.Delta]], desc: String) -> R<CommitDetails> {
        guard parents.count == deltas.count else {
            return .failure(WTF("commitDetails: parents.count == deltas.count"))
        }
        
        // exclude empty deltas from selection
        let filteredParents = parents.enumerated().filter { idx, _ in !deltas[idx].isEmpty }.map { $0.element }
        let filetredDeltas  = deltas.filter { !$0.isEmpty }
        let filteredAll     = filteredParents.asDictionary(other: filetredDeltas)
        
        if let firstDelta = filetredDeltas.first {
            return filteredAll | { CommitDetails(parents: filteredParents, deltasWithHunks: firstDelta, all: $0, desc: desc) }
        }
        
        return .success(CommitDetails(parents: [], deltasWithHunks: [], all: [:], desc: desc))
        
    }

}


extension Array where Element : Hashable {
    func asDictionary<Other>(other: Array<Other>) -> R<[Element:Other]> {
        guard self.count == other.count else {
            return .failure(WTF("can't map into dictionary: my count = \(self.count), other count: \(other.count)"))
        }
        let dic = Dictionary(uniqueKeysWithValues: self.enumerated().map { idx, element in (element, other[idx]) })
        return .success(dic)
    }
}


public struct CommitDetails {
    public let parents         : [OID]
    public let deltasWithHunks : [Diff.Delta]
    public let all             : [OID:[Diff.Delta]]
    public let desc            : String
    
    public static var emtpy : CommitDetails { CommitDetails(parents: [], deltasWithHunks: [], all: [:], desc: "")  }
    
    public func with(parent: Int) -> CommitDetails {
        guard parents.count > 0 else { return self }
        guard parent < parents.count else {
            return CommitDetails(parents: parents, deltasWithHunks: all.first!.value, all: all, desc: desc)
        }
        
        if let element = all[parents[parent]] {
            return CommitDetails(parents: parents, deltasWithHunks: element, all: all, desc: desc)
        }
        return self
    }
}

extension Commit {
    public var description : String {
        let subject = self.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let descr = self.body.trimmingCharacters(in: .whitespacesAndNewlines)

        return descr.count == 0 ? "\(subject)" :"\(subject)\r\n\(descr)"
    }
}


public enum CommitTarget {
    case HEADorWorkDir
    case commit(OID)
}

public enum Entries {
    case status(StatusIterator)
    case commit(CommitDetails)
    case headIsUnborn
}


public extension Entries {
    var count: Int {
        switch self {
        case .status(let statusIterator):
            return statusIterator.count
        case .commit(let commit):
            return commit.deltasWithHunks.count
        case .headIsUnborn:
            return 0
        }
    }
    
    var isCommit: Bool {
        switch self {
        case .commit(_):    return true
        default:            return false
        }
    }
    
    var isStatus: Bool {
        switch self {
        case .status(_):    return true
        default:            return false
        }
    }
    
    var asStatusIterator : StatusIterator? {
        switch self {
        case let .status(iterator): return iterator
        default:
            return nil
        }
    }
    
    var asCommitDetails : CommitDetails? {
        switch self {
        case let .commit(deltas): return deltas
        default:
            return nil
        }
    }
}


extension CommitTarget {
    func commit(in repo: Repository) -> R<Commit> {
        if case .commit(let oid) = self {
            return repo.commit(oid: oid)
        }
        return repo.headCommit()
    }
}
