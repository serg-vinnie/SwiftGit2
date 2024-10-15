
import Foundation
import Essentials
import Parsing

public struct GitFileID : Hashable {
    public let path: String
    public let blobID: BlobID
    public let commitID: CommitID?
    
    public var repoID : RepoID { blobID.repoID }
    public var fullPath : String { repoID.path + "/" + path }
    public var url : URL { URL(fileURLWithPath: fullPath) }
    public var displayName : String { url.lastPathComponent }
    
    public init(path: String, blobID: BlobID, commitID: CommitID?) {
        self.path = path
        self.blobID = blobID
        self.commitID = commitID
    }
}

public extension GitFileID {
    struct SubLines {
        let content : String
        let lines: [String.SubSequence]
        let isBinary: Bool
    }
    
    var subLines : R<SubLines> {
        blobID.content | { $0.asSubLines }
    }
}
