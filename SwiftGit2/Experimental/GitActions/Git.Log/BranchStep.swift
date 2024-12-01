import Foundation
import Essentials

internal struct BranchStep {
    let start: GitFileID
    let next: [GitFileID]
    let isFinal : Bool
    let isComplete : Bool
    
    var files : [GitFileID] { [start] + next }
}

extension GitFileID {
//    func branchStep(parentCommitID: CommitID) -> R<BranchStep> {
//        let start = self
//        var next = [GitFileID]()
//        
//        // first step should be targeted to the selected parent
//        // let t = __diffToParent(commitID: parentCommitID)
//        
//        
//        
//        return .notImplemented
//    }
    
    func branchStep(parentCommitID: CommitID) throws -> BranchStep {
        let start = self
        var next = [GitFileID]()
        
        let diff1 = try self.__diffToParent(commitID: parentCommitID).get()
        let deltas = diff1.asDeltas()
        let parentsOfParent = try parentCommitID.parents.get()
        let isFinal = parentsOfParent.count == 0
        
        if let delta = deltas.first {
            if delta.status == .modified {
                return BranchStep(start: start, next: [], isFinal: isFinal, isComplete: false)
            } else {
                throw WTF("branchStep(parentCommitID NOT IMPLEMENTED for deltas.status == \(delta.status)")
            }
        } else {
            let nextFileID = GitFileID(path: self.path, blobID: self.blobID, commitID: parentCommitID)
            next.append(nextFileID)
            return BranchStep(start: start, next: next, isFinal: parentsOfParent.count == 0, isComplete: false)
        }
        
        
    }
}

extension BranchStep {
    func expand(parentCommitID: CommitID? = nil) throws -> BranchStep {
        guard !isComplete && !isFinal else { return self }
        let fileID = self.next.last ?? self.start
        guard let commitID = fileID.commitID else { throw WTF("BranchStep.expand(...) fileID.commitID == nil") }
        let parents = try commitID.parents.get()
        
        guard let parent = parentCommitID ?? parents.first else {
            return BranchStep(start: self.start, next: self.next, isFinal: true, isComplete: true)
        }
        
        let parentsOfParent = try parent.parents.get()
        let isFinal = parentsOfParent.count == 0
        
        let diff1 = try fileID.__diffToParent(commitID: parent).get()
        guard let delta = diff1.asDeltas().first else {
            let nextFileID = GitFileID(path: fileID.path, blobID: fileID.blobID, commitID: parent)
            return BranchStep(start: start, next: next + [nextFileID], isFinal: isFinal, isComplete: false)
        }
                
        if delta.status == .modified {
            return BranchStep(start: self.start, next: self.next, isFinal: isFinal, isComplete: true)
        } else {
            throw WTF("branchStep(parentCommitID NOT IMPLEMENTED for deltas.status == \(delta.status)")
        }
    }
}

fileprivate extension GitFileID {
    func __diffToParent(commitID parentCommitID: CommitID) -> R<Diff> {
        guard let commitID else { return .wtf("commitID == nil")}
        
        return combine(commitID.treeID, parentCommitID.treeID)
            | { diff(old: $1, new: $0, path: self.path) }
    }
}

enum FileDiffToParent {
    case added
    case modified
    case none
}

fileprivate extension GitFileID {
    func diffToMainParent() -> R<FileDiffToParent> {
        guard let commitID else { return .wtf("commitID == nil")}
        
        do {
            let parents = try commitID.parents.get()
            if let parentCommitID = parents.first {
                let path = self.path
                let diff_ = combine(commitID.treeID, parentCommitID.treeID) | { SwiftGit2.diff(old: $1, new: $0, path: path) }
                let diff = try diff_.get()
                
                
                return .notImplemented
            } else {
                return .success(.added)
            }
            
        } catch {
            return .failure(error)
        }
    }
}

fileprivate func diff(old: TreeID, new: TreeID, path: String) -> R<Diff> {
    let repo = old.repoID.repo
    let oldTree = repo | { $0.treeLookup(oid: old.oid) }
    let newTree = repo | { $0.treeLookup(oid: new.oid) }
    
    let diffOptions = DiffOptions(pathspec: [path])
    let findOptions = Diff.FindOptions()
    
    return combine(repo, oldTree, newTree)
        | { repo, old, new in repo.diffTreeToTree(oldTree: old, newTree: new, options: diffOptions) }
        | { $0.findSimilar(options: findOptions) }
}
