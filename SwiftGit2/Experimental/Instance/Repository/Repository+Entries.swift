//
//  Repository+Entries.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 15.11.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

//extension Repository {
//   private func entries(target: CommitTarget, statusOptions: StatusOptions = StatusOptions(), findOptions: Diff.FindOptions = [.renames, .renamesFromRewrites] ) -> R<Entries> {
//       return self.statusConflictSafe(options: statusOptions)
//           .flatMap { status -> R<Entries> in
//               if status.isEmpty == false {
//                   return .success(.status(status))
//               }
//               
//               if self.headIsUnborn {
//                   return .success(.headIsUnborn)
//               }
//               
//               // self.headIsUnborn == false
//               return self.deltas(target: target, findOptions: findOptions)
//                  .map { .commit($0) } as R<Entries>
//            }
//        }
//}

extension Array where Element : Hashable {
    func asDictionary<Other>(other: Array<Other>) -> R<[Element:Other]> {
        guard self.count == other.count else {
            return .failure(WTF("can't map into dictionary: my count = \(self.count), other count: \(other.count)"))
        }
        let dic = Dictionary(uniqueKeysWithValues: self.enumerated().map { idx, element in (element, other[idx]) })
        return .success(dic)
    }
}

extension Commit {
    public var description : String {
        let summary = self.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let descr = self.body.trimmingCharacters(in: .whitespacesAndNewlines)

        return descr.count == 0 ? "\(summary)" :"\(summary)\n\n\(descr)"
    }
}


public enum CommitTarget {
    case HEADorWorkDir
    case commit(OID)
}

public enum Entries {
    case status(StatusIterator)
    case commit(CommitDeltas)
    case commitID(CommitID)
    case headIsUnborn
}


public extension Entries {
    var count: Int {
        switch self {
        case .status(let statusIterator):
            return statusIterator.count
        case .commit(let commit):
            return commit.deltasWithHunks.count
        case .commitID(_):
            return 0
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
    
    var asCommitDetails : CommitDeltas? {
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
