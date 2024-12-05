
import Foundation
import Essentials
import OrderedCollections

internal struct FileHistoryStep {
    let branchSteps : [BranchStep]
    var files : [GitFileID] { branchSteps.flatMap { $0.files } }
}

extension FileHistoryStep {
    func nextStep() throws -> FileHistoryStep {
        guard let prevStep = branchSteps.first else { throw WTF("FileHistoryStep.nextStep: prevStep == nil") }
        guard let prevFileID = prevStep.files.last else { throw WTF("FileHistoryStep.nextStep: fileID == nil") }
        guard let prevCommitID = prevFileID.commitID   else { throw WTF("FileHistoryStep.nextStep: commitID == nil") }
        
        let prevParents = try prevCommitID.parents.get()
        
        if prevParents.isEmpty {
            throw WTF("FileHistoryStep.nextStep: parents.isEmpty")
        } else if prevParents.count == 1, let parent = prevParents.first {
            let diff1 = try prevFileID.__diffToParent(commitID: parent).get()
            if let delta = diff1.asDeltas().first {
                
            } else {
                let treeID = try parent.treeID.get()
                let blobID = try treeID.blob(name: prevFileID.path).get()
                let nextFileID = GitFileID(path: prevFileID.path, blobID: blobID, commitID: parent)
                let nextParents = try parent.parents.get()
//                return nextFileID.
            }
        } else {
            throw WTF("parents.count > 1 NOT IMPLEMENTED")
        }
        
        throw WTF("FileHistoryStep.nextStep not implemented")
    }
}

func branchStep(starting fileID: GitFileID, parent: CommitID) throws -> BranchStep {
    let parentsOfParent = try parent.parents.get()
    let isFinal = parentsOfParent.count == 0
    let diff = try fileID.__diffToParent(commitID: parent).get()
    
    guard let delta = diff.asDeltas().first else {
        let nextFileID = GitFileID(path: fileID.path, blobID: fileID.blobID, commitID: parent)
        return BranchStep(start: fileID, next: [nextFileID], isFinal: isFinal, isComplete: isFinal)
    }
//    if let delta = diff.asDeltas().first {
//        
//    } else {
//        let treeID = try parent.treeID.get()
//        let blobID = try treeID.blob(name: fileID.path).get()
//        let nextFileID = GitFileID(path: fileID.path, blobID: blobID, commitID: parent)
//        let nextParents = try parent.parents.get()
//    }
    
    throw WTF("step(from not implemented")
}
//extension Array where Element == CommitID {
//    
//}


internal extension GitFileID {
    func historyStep() -> R<FileHistoryStep> {
        Result { try _historyStep() }
    }
    
    private func _historyStep() throws -> FileHistoryStep {
        guard let commitID else { throw WTF("commitID == nil at GitFileID.historyStep()") }
        
        let parents = try commitID.parents.get()
        
        if parents.isEmpty {
            
            let branchStep = BranchStep(start: self, next: [], isFinal: true, isComplete: true)
            return FileHistoryStep(branchSteps: [branchStep])
            
        } else if parents.count == 1, let parent = parents.first {
            
            let branchStep = try self.branchStep(parentCommitID: parent)
            return FileHistoryStep(branchSteps: [branchStep])
            
        } else {
            throw WTF("parents.count > 1 NOT IMPLEMENTED")
        }
    }
}


