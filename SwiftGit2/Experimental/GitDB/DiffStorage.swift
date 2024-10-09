
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
    
    init(diffOptions: DiffOptions = DiffOptions(), findOptions: Diff.FindOptions = Diff.FindOptions()) {
        self.diffOptions = diffOptions
        self.findOptions = findOptions
    }
    
    var diffDeltas = LockedVar<[TreeDiffID:[Diff.Delta]]>([:])
        
    func diff(old: TreeID?, new: TreeID?) -> R<[Diff.Delta]> {
        if old == nil, let new { return diff(new: new) }
        if new == nil, let old { return diff(old: old) }
        guard let new, let old else { return .wtf("at least one argument shoud be not nil") }
        
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, oldTree, newTree) | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: self.diffOptions) }
        return diff | { $0.asDeltas() }
    }
    
    private func diff(old: TreeID) -> R<[Diff.Delta]> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        
        let diff = combine(repo, oldTree) | { repo, old in repo.diffTreeToTree(oldTree: old, newTree: nil, options: self.diffOptions) }
        return diff | { $0.asDeltas() }
    }
    
    private func diff(new: TreeID) -> R<[Diff.Delta]> {
        let repo = new.repoID.repo
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diff = combine(repo, newTree) | { repo, new in repo.diffTreeToTree(oldTree: nil, newTree: new, options: self.diffOptions) }
        return diff | { $0.asDeltas() }
    }
}

public struct TreeDiffID : Hashable, Identifiable {
    public var id: String { (oldTree?.oid.description ?? "nil") + "_" + (newTree?.oid.description ?? "nil") }
    
    // both nils will return error
    let oldTree : TreeID?
    let newTree : TreeID?
}


public struct GitDiff {
    public let repoID : RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitDiff {
    
}

public struct ParentDiff : Hashable, Identifiable {
    public var id: Int { idx }
    
    let idx: Int
    let commitID: CommitID
    
    
//    var deltas: R<[Diff.Delta]> { commitID.diffToParent(oid: commitID.oid) }
}

public enum DiffToParent {
    case isInitial // not a diff, every file is "Added"
    case parent(SwiftGit2.Diff)
}

public extension CommitID {
    func diffToParent() -> R<DiffToParent> {
        self.parents | { $0.diff() }
    }
}

extension Array where Element == CommitID {
    func diff() -> R<DiffToParent> {
        if self.count == 0 {
            return .success(.isInitial)
        }
        
        return .notImplemented
    }
}
