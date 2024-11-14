import Foundation
import Essentials

internal struct BranchStep {
    let parent: CommitID
    let files: [GitFileID]
    let isFinal : Bool
}

extension GitFileID {
    func branchStep(commitID parentCommitID: CommitID, base: CommitID?) -> R<BranchStep> {
        guard base == nil else { return .notImplemented }
        
        let t = _diffToParent(commitID: parentCommitID)
        
        return .notImplemented
    }
}


//fileprivate extension GitFileID {
//    func branchStep(commitID parentCommitID: CommitID) -> R<BranchStep> {
//        _diffToParent(commitID: parentCommitID)
//        | { $0.asDeltas() }
//        | {
//            if $0.isEmpty {
//                let fileID = GitFileID(path: self.path, blobID: self.blobID, commitID: parentCommitID)
//                return  .success(ParentFileID(fileID: fileID, endOfSearch: false))
//            } else {
//                return $0.first.asNonOptional("first delta for parent == nil") | { $0.newParentFileID(commitID: parentCommitID) }
//            }
//        }
//    }
//    
//}
