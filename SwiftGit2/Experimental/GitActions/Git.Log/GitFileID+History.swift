
import Foundation
import Clibgit2
import Essentials

extension GitFileID {
    var findInParents : R<GitFileID> {
        guard let commitID else { return .wtf("commitID == nil") }
        
        commitID.parents
        
        return .notImplemented
    }
}

public extension CommitID {
    func matchFile(path: String) -> R<GitFileID> {
        
        return .notImplemented
    }
}
