
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
        guard let fileID = prevStep.files.last else { throw WTF("FileHistoryStep.nextStep: fileID == nil") }
        guard let commitID = fileID.commitID   else { throw WTF("FileHistoryStep.nextStep: commitID == nil") }
        
        let parents = try commitID.parents.get()
        
        if parents.isEmpty {
            throw WTF("FileHistoryStep.nextStep: parents.isEmpty")
        } else if parents.count == 1, let parent = parents.first {
            
        } else {
            throw WTF("parents.count > 1 NOT IMPLEMENTED")
        }
        
        throw WTF("FileHistoryStep.nextStep not implemented")
    }
}

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


