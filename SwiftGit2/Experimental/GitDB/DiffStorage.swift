
import Foundation
import Essentials
import Clibgit2

var _diffStorages = LockedVar<[RepoID:DiffStorage]>([:])

extension RepoID {
    var diffStorage : DiffStorage { _diffStorages.item(key: self) { _ in DiffStorage() } }
}



class DiffStorage {
    let diffOptions : DiffOptions
    let findFlags : Diff.FindFlags
    var treeDiffs   = LockedVar<[TreeDiffID:TreeDiff]>([:])
    var blobDiffs   = LockedVar<[BlobDiffID:[Diff.Hunk]]>([:])
    
    init(diffOptions: DiffOptions = DiffOptions(), findOptions: Diff.FindFlags = Diff.FindFlags()) {
        self.diffOptions = diffOptions
        self.findFlags = findOptions
    }
    
    func diff(old: BlobID?, new: BlobID?) -> R<[Diff.Hunk]> {
        let id = BlobDiffID(oldBlob: old, newBlob: new)
        
        if let hunks = self.blobDiffs[id] {
            return .success(hunks)
        }
        
        return _diff(old: old, new: new)
            .onSuccess {
                blobDiffs[id] = $0
            }
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
        return diff | { $0.findSimilar(flags: self.findFlags) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    func diff(old: TreeID) -> R<TreeDiff> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        
        let diff = combine(repo, oldTree) | { repo, old in repo.diffTreeToTree(oldTree: old, newTree: nil, options: self.diffOptions) }
        return diff | { $0.findSimilar(flags: self.findFlags) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
    
    func diff(new: TreeID) -> R<TreeDiff> {
        let repo = new.repoID.repo
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, newTree) | { repo, new in repo.diffTreeToTree(oldTree: nil, newTree: new, options: self.diffOptions) }
        return diff | { $0.findSimilar(flags: self.findFlags) } | { $0.asDeltas() } | { TreeDiff(deltas: $0) }
    }
}


private extension DiffStorage {
    func _diff(old: BlobID?, new: BlobID?) -> R<[Diff.Hunk]> {
        if old == nil, let new { return diff(new: new) }
        if new == nil, let old { return diff(old: old) }
        guard let new, let old else { return .wtf("at least one argument shoud be not nil") }
        
        let repo = old.repoID.repo
        let oldBlob = repo | { $0.blob(oid: old.oid) }
        let newBlob = repo | { $0.blob(oid: new.oid) }
        
        return combine(repo, oldBlob, newBlob) | { repo, old, new in
            repo.diffBlobs(old: old, new: new, options: self.diffOptions)
        }
    }
    
    func diff(old: BlobID) -> R<[Diff.Hunk]> {
        let repo = old.repoID.repo
        let oldBlob = repo | { $0.blob(oid: old.oid) }

        return combine(repo, oldBlob) | { repo, old in repo.diffBlobs(old: old, new: nil, options: self.diffOptions) }
    }
    
    func diff(new: BlobID) -> R<[Diff.Hunk]> {
        let repo = new.repoID.repo
        let newBlob = repo | { $0.blob(oid: new.oid) }
        
        return combine(repo, newBlob) | { repo, new in repo.diffBlobs(old: nil, new: new, options: self.diffOptions) }
    }
}
