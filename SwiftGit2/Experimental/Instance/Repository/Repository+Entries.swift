////
////  Repository+Entries.swift
////  SwiftGit2-OSX
////
////  Created by UKS on 15.11.2021.
////  Copyright © 2021 GitHub, Inc. All rights reserved.
////
//
//import Foundation
//import Essentials
//
//extension Repository {
//   public func entries(target: CommitTarget, statusOptions: StatusOptions = StatusOptions(), findOptions: Diff.FindOptions) -> R<Entries> {
//       return self.statusConflictSafe(options: statusOptions)
//           .if(\.isEmpty,
//                then: { _ in
//               if self.headIsUnborn {
//                   return .success(.headIsUnborn)
//               } else {
//                   return self.deltas(target: target, findOptions: findOptions)
//                       .map { .commit($0) } as R<Entries>
//               }
//           },
//
//                else: { status in
//                   .success(.status(status))
//           })
//   }
//}
//
//extension Repository {
//    func deltas(target: CommitTarget, findOptions: Diff.FindOptions) -> R<CommitDetails> {
//        if headIsUnborn {
//            return .success(CommitDetails(parents: [], deltas: [], all: [:], desc: ""))
//        }
//
//        let commit      = target.commit(in: self)
//        let desc        = commit | { $0.description }
//        let commitTree  = commit | { $0.tree() }
//        let parents     = commit | { $0.parents() }
//
//        if case .success(let parents) = parents {
//            if parents.isEmpty {
//                let deltas = commitTree | { self.diffTreeToTree(oldTree: nil, newTree: $0) } | { $0.asDeltas() }
//
//                return combine(deltas, desc) | { CommitDetails(parents: [], deltas: $0, all: [:], desc: $1) }
//            }
//        }
//
//        let parentOIDs  = parents | { $0 | { $0.oid } }
//        let parentTrees = parents | { $0 | { $0.tree() } }
//        let deltas      = combine(commitTree, parentTrees) | { tree, parents in parents | {
//            self.diffTreeToTree(oldTree: $0, newTree: tree)
//                | { $0.findSimilar(options: findOptions) }
//                | { $0.asDeltas() } } }
//
//        return combine(parentOIDs, deltas, desc) | { commitDetails(parents: $0, deltas: $1, desc: $2) }
//    }
//}
//
//
//struct CommitDetails {
//    let parents     : [OID]
//    let deltas      : [Diff.Delta]
//    let all         : [OID:[Diff.Delta]]
//    let desc        : String
//
//    func with(parent: Int) -> CommitDetails {
//        guard parents.count > 0 else { return self }
//        guard parent < parents.count else {
//            return CommitDetails(parents: parents, deltas: all.first!.value, all: all, desc: desc)
//        }
//
//        if let element = all[parents[parent]] {
//            return CommitDetails(parents: parents, deltas: element, all: all, desc: desc)
//        }
//        return self
//    }
//}
//
//extension CommitDetails {
//    public var description : String {
//        let subject = self.summary.trimmingCharacters(in: .whitespacesAndNewlines)
//        let descr = self.body.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        return descr.count == 0 ? "\(subject)" :"\(subject)\r\n\(descr)"
//
//    }
//}
//
//
//public enum CommitTarget {
//    case HEADorWorkDir
//    case commit(OID)
//}
//
//public enum Entries {
//    case status(StatusIterator)
//    case commit(CommitDetails)
//    case headIsUnborn
//}
