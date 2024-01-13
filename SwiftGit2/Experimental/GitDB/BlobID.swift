
import Foundation
import Essentials

public struct BlobID {
    public let oid: OID
    public let repoID: RepoID
    
    public init(oid: OID, repoID: RepoID) {
        self.oid = oid
        self.repoID = repoID
    }
}

public extension BlobID {
    enum Content {
        case binary(Data)
        case text(String)
    }
    
    var data : R<Data> { repoID.repo | { $0.blob(oid: oid) | { $0.asData } } }
    var content : R<BlobID.Content> { repoID.repo | { $0.blob(oid: oid) | { $0.content } } }
}

extension Blob {
    var content : R<BlobID.Content> {
        if isBinary {
            return .success(.binary(asData))
        } else {
            return asData.asString() | { .text($0) }
        }
    }
}
