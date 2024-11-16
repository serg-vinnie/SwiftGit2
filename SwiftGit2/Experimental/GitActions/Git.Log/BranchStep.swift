import Foundation
import Essentials

internal struct BranchStep {
    let start: GitFileID
    let next: [GitFileID]
    let isFinal : Bool
}

extension GitFileID {
    func branchStep(commitID parentCommitID: CommitID) -> R<BranchStep> {
        let start = self
        var next = [GitFileID]()
        
//        let t = __diffToParent(commitID: parentCommitID)
        
        return .notImplemented
    }
    
    func branchStep(commitID parentCommitID: CommitID, base: CommitID) -> R<BranchStep> {
        
        let start = self
        var next = [GitFileID]()
        
//        let t = __diffToParent(commitID: parentCommitID)
        
        return .notImplemented
    }
}

//fileprivate extension GitFileID {
//    func __diffToParent(commitID parentCommitID: CommitID) -> R<Diff> {
//        guard let commitID else { return .wtf("commitID == nil")}
//        
//        return combine(commitID.treeID, parentCommitID.treeID)
//            | { diff(old: $1, new: $0, path: self.path) }
//    }
//}

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
