
import Foundation
import Essentials

public struct GitFileID : Hashable {
    public let path: String
    public let blobID: BlobID
    public let commitID: CommitID?
    
    public var repoID : RepoID { blobID.repoID }
    public var fullPath : String { repoID.path + "/" + path }
    public var url : URL { URL(fileURLWithPath: fullPath) }
    
    public init(path: String, blobID: BlobID, commitID: CommitID?) {
        self.path = path
        self.blobID = blobID
        self.commitID = commitID
    }
}
