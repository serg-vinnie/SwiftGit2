
import Foundation
import Essentials

public struct GitFileID {
    public let path: String
    public let blobID: BlobID
    public let commitID: CommitID?
    
    var repoID : RepoID { blobID.repoID }
    
    public init(path: String, blobID: BlobID, commitID: CommitID?) {
        self.path = path
        self.blobID = blobID
        self.commitID = commitID
    }
}
