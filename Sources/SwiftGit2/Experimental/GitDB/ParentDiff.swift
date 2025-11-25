
import Foundation
import Essentials
import Clibgit2


extension ParentDiff : CustomStringConvertible {
    public var description: String {
        "\(idx + 1)/\(total) - \(diff.deltas.count) deltas, \(diff.folders.count) folders"
    }
}

public struct ParentDiff : Hashable, Identifiable {
    public var id: Int { idx }
    
    public let idx     : Int
    public let total   : Int
    public let commitID: CommitID
    public let parentID: CommitID?
    public let diff    : TreeDiff
}

public extension CommitID {
    func diffToParent() -> R<[ParentDiff]> {
        combine(self.treeID,self.parents) | { $1.diff(treeID: $0, commitID: self) }
    }
}

private extension Array where Element == CommitID {
    func diff(treeID: TreeID, commitID: CommitID) -> R<[ParentDiff]> {
        let repoID = treeID.repoID
        if count == 0 {
            return repoID.diffStorage.diff(old: nil, new: treeID)
                | { diff in ParentDiff(idx: 0, total: 1, commitID: commitID, parentID: nil, diff: diff)}
                | { [$0] }
        }

        return self.enumerated()
            .map { $0 } // to Array
            .flatMap { idx, commitID in
                commitID.treeID | { oldTreeID in
                    repoID.diffStorage.diff(old: oldTreeID, new: treeID) | { diff in
                        ParentDiff(idx: idx, total: self.count, commitID: commitID, parentID: commitID, diff: diff)
                    }
                }
        }
    }
}
