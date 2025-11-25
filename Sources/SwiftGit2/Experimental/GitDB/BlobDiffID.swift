
import Foundation
import Essentials
import Clibgit2

public struct BlobDiffID : Hashable, Identifiable {
    public var id: String { (oldBlob?.oid.description ?? "nil") + "_" + (newBlob?.oid.description ?? "") }
    
    // both nils will return error
    public let oldBlob : BlobID?
    public let newBlob : BlobID?
    
    public var hunks : R<[Diff.Hunk]> {
        guard let repoID = newBlob?.repoID ?? oldBlob?.repoID else { return .wtf("can't resolve repoID, both blobID are nil")}
        return repoID.diffStorage.diff(old: oldBlob, new: newBlob)
    }
}
