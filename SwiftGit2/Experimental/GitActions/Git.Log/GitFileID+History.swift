
import Foundation
import Clibgit2
import Essentials

public extension GitFileID {
    func walk() -> R<[GitFileID]> {
        Result { try _walk() }
    }
    
    private func _walk() throws -> [GitFileID] {
        var list = [GitFileID]([self])
        
        var diff = try list.nextDiff()
        
        while !diff.isEmpty {
            list.append(contentsOf: diff)
            diff = try list.nextDiff()
        }
        
        return list
    }
}

// if the array is a list of parents
internal extension Array where Element == GitFileID {
    func nextDiff() throws -> [GitFileID] {
        guard let last else { throw WTF("nextDiff: array [GitFileID] is empty") }
        
        var current_step = try last.step().get()
        var accumulator = [GitFileID]()
        
        while !current_step.isEmpty {
            accumulator.append(contentsOf: current_step)
            if !last.isDifferent(to: current_step) {
                current_step = try current_step.nextStep().get()
            } else {
                current_step = []
            }
        }
        
        return accumulator
    }
    
    func nextStep() -> R<[GitFileID]> {
        guard let last else { return .wtf("nextStep: array [GitFileID] is empty") }
        return last.step() //| { self.appending(contentsOf: $0) }
    }
}

internal extension Array where Element == ParentFileID {
    func nextStepAsParents() -> R<[GitFileID]> {
        guard let last else { return .success([]) } // no parents: end
        
        if self.count == 1 {
            return .success([last.fileID])
        }
        
        return .notImplemented
    }
}

internal extension GitFileID {
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
    
    var parentFileIDs : R<[ParentFileID]> {
        guard let commitID else { return .wtf("commitID == nil") }
        return commitID.parents | { $0.flatMap { self.diffToParent(commitID: $0) } }
    }
}

extension Diff.Delta : CustomStringConvertible {
    public var description: String {
        guard let oldFile else { return "Diff.Delta.oldFile == nil" }
        guard let newFile else { return "Diff.Delta.oldFile == nil" }
        
        let oids = oldFile.oid.oidShort + ":" + newFile.oid.oidShort + " "
        
        if self.status == .renamed {
            return "renamed:" + oids + oldFile.path + " -> " + newFile.path
        }
        
        if oldFile.path == newFile.path {
            return oids + oldFile.path
        } else {
            return oids + oldFile.path + " -> " + newFile.path
        }
    }
    
    fileprivate func newParentFileID(commitID: CommitID) -> R<ParentFileID> {
        guard let newFile else { return .wtf("newFile == nil") }
        
        let blobID = BlobID(repoID: commitID.repoID, oid: newFile.oid, path: newFile.path)
        let fileID = GitFileID(path: newFile.path, blobID: blobID, commitID: commitID)
        let parentFileID = ParentFileID(fileID: fileID, endOfSearch: self.status == .added)
        return .success(parentFileID)
    }
}

internal struct ParentFileID {
    let fileID: GitFileID
    let endOfSearch: Bool
}

fileprivate extension GitFileID {
    func diffToParent(commitID parentCommitID: CommitID) -> R<ParentFileID> {
        _diffToParent(commitID: parentCommitID)
            | { $0.asDeltas() }
            | {
                if $0.isEmpty {
                    let fileID = GitFileID(path: self.path, blobID: self.blobID, commitID: parentCommitID)
                    return  .success(ParentFileID(fileID: fileID, endOfSearch: false))
                } else {
                    return $0.first.asNonOptional("first delta for parent == nil") | { $0.newParentFileID(commitID: parentCommitID) }
                }
            }
    }
    
    func _diffToParent(commitID parentCommitID: CommitID) -> R<Diff> {
        guard let commitID else { return .wtf("commitID == nil")}
        return combine(commitID.treeID, parentCommitID.treeID)
            | { _diff(old: $1, new: $0) }
    }
    
    func _diff(old: TreeID, new: TreeID) -> R<Diff> {
        let repo = old.repoID.repo
        let oldTree = repo | { $0.treeLookup(oid: old.oid) }
        let newTree = repo | { $0.treeLookup(oid: new.oid) }
        
//        print("pathspec [\(self.path)]")
        let diffOptions = DiffOptions(pathspec: [self.path])
        let findOptions = Diff.FindOptions()
        
//        print("old blob",old.blob(name: self.path))
//        print("new blob",new.blob(name: self.path))

        return combine(repo, oldTree, newTree) 
            | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: diffOptions) }
            | { $0.findSimilar(options: findOptions) }
    }
}
