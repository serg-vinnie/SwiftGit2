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
    var initialBranchStep : BranchStep { BranchStep(start: self, next: [], isFinal: false, isComplete: false) }
    
    func branchStep(parentCommitID: CommitID) throws -> BranchStep {
        var step = try initialBranchStep.expand(parentCommitID: parentCommitID)
        while !step.isComplete {
            step = try step.expand()
        }
        return step
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
            return BranchStep(start: start, next: next + [nextFileID], isFinal: isFinal, isComplete: isFinal)
        }
                
        if delta.status == .modified {
            return BranchStep(start: self.start, next: self.next, isFinal: isFinal, isComplete: true)
        } else if delta.status == .added {
            return BranchStep(start: self.start, next: self.next, isFinal: true, isComplete: true)
        } else if delta.status == .renamed {
            throw WTF("BranchStep.expand(...) NOT IMPLEMENTED for deltas.status == \(delta.status)")
        } else {
            throw WTF("BranchStep.expand(...) NOT IMPLEMENTED for deltas.status == \(delta.status)")
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
