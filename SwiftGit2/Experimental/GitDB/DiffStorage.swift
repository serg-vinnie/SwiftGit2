
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
    var treeDiffs   = LockedVar<[TreeDiffID:TreeDiff]>([:])
    
    init(diffOptions: DiffOptions = DiffOptions(), findOptions: Diff.FindOptions = Diff.FindOptions()) {
        self.diffOptions = diffOptions
        self.findOptions = findOptions
    }
    
    func diff(old: TreeID?, new: TreeID?) -> R<TreeDiff> {
        let id = TreeDiffID(oldTree: old, newTree: new)
        
        if let diff = self.treeDiffs[id] {
            return .success(diff)
        }
        
        return _diff(old: old, new: new)
            .onSuccess {
                self.treeDiffs[id] = $0
            }
    }
}

private extension DiffStorage {
    func _diff(old: TreeID?, new: TreeID?) -> R<TreeDiff> {
        if old == nil, let new { return diff(new: new) }
        if new == nil, let old { return diff(old: old) }
        guard let new, let old else { return .wtf("at least one argument shoud be not nil") }
        
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, oldTree, newTree) | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: self.diffOptions) }
        return diff | { $0.findSimilar(options: self.findOptions) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    func diff(old: TreeID) -> R<TreeDiff> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        
        let diff = combine(repo, oldTree) | { repo, old in repo.diffTreeToTree(oldTree: old, newTree: nil, options: self.diffOptions) }
        return diff | { $0.findSimilar(options: self.findOptions) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    func diff(new: TreeID) -> R<TreeDiff> {
        let repo = new.repoID.repo
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, newTree) | { repo, new in repo.diffTreeToTree(oldTree: nil, newTree: new, options: self.diffOptions) }
        return diff | { $0.findSimilar(options: self.findOptions) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
}
