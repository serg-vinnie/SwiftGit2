
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
    }
    
    var subLines : R<SubLines> {
        let content = self.blobID.content | { $0.asString }
        let lines = content | { $0.subStrings }
        return combine(content, lines) | { SubLines(content: $0, lines: $1) }
    }
}
