
import Foundation
import Clibgit2
import Essentials

extension GitFileID {
    var parentFiles : R<[GitFileID]> {
        guard let commitID else { return .wtf("commitID == nil") }
        return commitID.parents | { $0.flatMap { self.diffToParent(commitID: $0) } }
    }
}

extension Diff.Delta : CustomStringConvertible {
    public var description: String {
        guard let oldFile else { return "Diff.Delta.oldFile == nil" }
        guard let newFile else { return "Diff.Delta.oldFile == nil" }
        
        let oids = oldFile.oid.oidShort + ":" + newFile.oid.oidShort + " "
        
        if oldFile.path == newFile.path {
            return oids + oldFile.path
        } else {
            return oids + oldFile.path + " -> " + newFile.path
        }
    }
    
    func newFileID(commitID: CommitID) -> R<GitFileID> {
        guard let newFile else { return .wtf("newFile == nil") }
        
        let blobID = BlobID(repoID: commitID.repoID, oid: newFile.oid, path: newFile.path)
        return .success(GitFileID(path: newFile.path, blobID: blobID, commitID: commitID))
    }
}

fileprivate extension GitFileID {
    func diffToParent(commitID parentCommitID: CommitID) -> R<GitFileID> {
        _diffToParent(commitID: parentCommitID)
            | { $0.asDeltas() }
            | { $0.first.asNonOptional("first delta for parent == nil") }
            | { $0.newFileID(commitID: parentCommitID) }
    }
    
//    func fileFrom(diff: Diff) -> GitFileID {
////        diff.asDeltas()
//    }
    
    func _diffToParent(commitID parentCommitID: CommitID) -> R<Diff> {
        guard let commitID else { return .wtf("commitID == nil")}
        return combine(commitID.treeID, parentCommitID.treeID)
            | { _diff(old: $1, new: $0) }
    }
    
    func _diff(old: TreeID, new: TreeID) -> R<Diff> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
        let diffOptions = DiffOptions(pathspec: [self.path])
        let findOptions = Diff.FindOptions()

        return combine(repo, oldTree, newTree) 
            | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: diffOptions) }
            | { $0.findSimilar(options: findOptions) }
    }
}
