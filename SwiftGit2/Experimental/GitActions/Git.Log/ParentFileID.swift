
import Foundation
import Essentials

internal struct ParentFileID {
    let fileID: GitFileID
    let endOfSearch: Bool
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
