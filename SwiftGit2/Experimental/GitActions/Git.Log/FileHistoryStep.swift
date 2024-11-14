
import Foundation
import Essentials
import OrderedCollections

internal struct FileHistoryStep {
    let files : [BranchStep]
}


internal extension GitFileID {
//    var parentFileIDs : R<[ParentFileID]> {
//        guard let commitID else { return .wtf("commitID == nil") }
//        return commitID.parents | { $0.flatMap { self.diffToParent(commitID: $0) } }
//    }
    
    func historyStep() -> R<FileHistoryStep> {
        guard let commitID else { return .wtf("commitID == nil at GitFileID.historyStep()") }
        return commitID.parents | { $0.fileHistoryStep() }
    }
}


internal extension Array where Element == CommitID {
    func fileHistoryStep() -> R<FileHistoryStep> {
        guard let last else { return .success(FileHistoryStep(files: [])) } // no parents: end
        
//        if self.count == 1 {
//            return .success([last.fileID])
//        }
        
        return .notImplemented
    }
}
