
import Foundation
import Clibgit2
import Essentials

public extension GitFileID {
    func walk() -> R<[GitFileID]> {
        
        
        return .notImplemented
    }
}

extension Result where Success == [GitFileID], Failure == Error {
    func needNextStep(for fileID: GitFileID) -> Bool {
        switch self {
        case .success(let me):
            if me.isEmpty { return false }
            return !fileID.isDifferent(to: me)
            
        case .failure(_):       return false
        }
    }
}


internal extension Array where Element == GitFileID {
    func walk() -> R<[GitFileID]> {
        guard let last else { return .wtf("array [GitFileID] is empty") }
        
        var steps = last.step()
//        var nextStep
        while steps.needNextStep(for: last) {
            steps = steps | { $0.nextStep() }
        }
        
        return steps
    }
    
    func nextStep() -> R<[GitFileID]> {
        guard let last else { return .wtf("array [GitFileID] is empty") }
        return last.step() | { self.appending(contentsOf: $0) }
    }
    
    func nextStepAsParents() -> R<[GitFileID]> {
        guard let last else { return .wtf("array [GitFileID] is empty")}
        
        if self.count == 1 {
            return .success([last])
        }
        
        return .notImplemented
    }
}

fileprivate extension GitFileID {
    func step() -> R<[GitFileID]> {
        return parentFileIDs | { $0.nextStepAsParents() }
    }
    
    func isDifferent(to others: [GitFileID]) -> Bool {
        others.first { self.isDifferent(to: $0) } != nil
    }
    
    func isDifferent(to other: GitFileID) -> Bool {
        if self.path != other.path { return true }
        if self.blobID.oid != other.blobID.oid { return true }
        return false
    }
    
    var parentFileIDs : R<[GitFileID]> {
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
