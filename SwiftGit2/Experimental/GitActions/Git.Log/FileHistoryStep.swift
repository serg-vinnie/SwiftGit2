
import Foundation
import Essentials
import OrderedCollections

internal struct FileHistoryStep {
    let branchSteps : [BranchStep]
    var files : [GitFileID] { branchSteps.flatMap { $0.files } }
}


internal extension GitFileID {
//    var parentFileIDs : R<[ParentFileID]> {
//        guard let commitID else { return .wtf("commitID == nil") }
//        return commitID.parents | { $0.flatMap { self.diffToParent(commitID: $0) } }
//    }
    
    func historyStep() -> R<FileHistoryStep> {
        Result { try _historyStep() }
    }
    
    private func _historyStep() throws -> FileHistoryStep {
        guard let commitID else { throw WTF("commitID == nil at GitFileID.historyStep()") }
        
        let parents = try commitID.parents.get()
        
        if parents.isEmpty {
            let branchStep = BranchStep(start: self, next: [], isFinal: true)
            return FileHistoryStep(branchSteps: [branchStep])
        } else if parents.count == 1 {
            throw WTF("parents.count == 1 NOT IMPLEMENTED")
        } else {
            throw WTF("parents.count > 1 NOT IMPLEMENTED")
        }
        
        
//        throw WTF("NOT IMPLEMENTED")
    }
}


// Array of parents
internal extension Array where Element == CommitID {
    func fileHistoryStep(fileID: GitFileID) -> R<FileHistoryStep> {
        guard let last else { return .success(FileHistoryStep(branchSteps: [])) } // no parents: end
        
        if self.count == 1 {
            return fileID.branchStep(commitID: last) | { FileHistoryStep(branchSteps: [$0]) }
        }
        
        return .notImplemented
    }
}
