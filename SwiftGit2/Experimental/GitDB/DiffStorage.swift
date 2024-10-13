
import Foundation
import Essentials
import Clibgit2

var _diffStorages = LockedVar<[RepoID:DiffStorage]>([:])

extension RepoID {
    var diffStorage : DiffStorage { _diffStorages.item(key: self) { _ in DiffStorage() } }
}

class DiffStorage {
    let diffOptions : DiffOptions
    let findOptions : Diff.FindOptions
    var diffs       = LockedVar<[TreeDiffID:TreeDiff]>([:])
    
    init(diffOptions: DiffOptions = DiffOptions(), findOptions: Diff.FindOptions = Diff.FindOptions()) {
        self.diffOptions = diffOptions
        self.findOptions = findOptions
    }
    
    func diff(old: TreeID?, new: TreeID?) -> R<TreeDiff> {
        let id = TreeDiffID(oldTree: old, newTree: new)
        
        if let diff = self.diffs[id] {
            return .success(diff)
        }
        
        return _diff(old: old, new: new)
            .onSuccess {
                self.diffs[id] = $0
            }
    }
    
    private func _diff(old: TreeID?, new: TreeID?) -> R<TreeDiff> {
        if old == nil, let new { return diff(new: new) }
        if new == nil, let old { return diff(old: old) }
        guard let new, let old else { return .wtf("at least one argument shoud be not nil") }
        
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, oldTree, newTree) | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: self.diffOptions) }
        return diff | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    private func diff(old: TreeID) -> R<TreeDiff> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        
        let diff = combine(repo, oldTree) | { repo, old in repo.diffTreeToTree(oldTree: old, newTree: nil, options: self.diffOptions) }
        return diff | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    private func diff(new: TreeID) -> R<TreeDiff> {
        let repo = new.repoID.repo
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, newTree) | { repo, new in repo.diffTreeToTree(oldTree: nil, newTree: new, options: self.diffOptions) }
        return diff | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
}

extension ParentDiff : CustomStringConvertible {
    public var description: String {
        "\(idx + 1)/\(total) - \(diff.deltas.count) deltas"
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

extension Array where Element == CommitID {
    func diff(treeID: TreeID, commitID: CommitID) -> R<[ParentDiff]> {
        let repoID = treeID.repoID
        if count == 0 {
            return repoID.diffStorage.diff(old: nil, new: treeID) 
                | { diff in ParentDiff(idx: 0, total: 1, commitID: commitID, parentID: commitID, diff: diff)}
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
