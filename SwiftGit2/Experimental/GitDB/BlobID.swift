
import Foundation
import Essentials

public struct BlobID : Hashable {
    public let oid: OID
    public let repoID: RepoID
    public let path: String?
    
    public init(repoID: RepoID, oid: OID,  path: String? = nil) {
        self.oid = oid
        self.repoID = repoID
        self.path = path
    }
}

public extension BlobID {
    var exists : Bool {
        (repoID.repo | { $0.blob(oid: oid) }).maybeSuccess != nil
    }
    
    enum Content {
        case binary(Data)
        case text(String)
        
        public var asString : R<String> {
            switch self {
            case .text(let str): return .success(str)
            case .binary(_): return .wtf("content is binary")
            }
        }
        
        public var asSubLines : R<GitFileID.SubLines> {
            switch self {
            case .text(let str):
                return str.subStrings | { .init(content: str, lines: $0, isBinary: false) }
                
            case .binary(_):
                return .success(.init(content: "", lines: [], isBinary: true))
            }
        }
    }
    
    var data : R<Data> { repoID.repo | { $0.blob(oid: oid) | { $0.asData } } }
    var content : R<BlobID.Content> { repoID.repo | { $0.blob(oid: oid) | { $0.content } } }
    var url : R<URL> { path.asNonOptional("BlobID.path") | { repoID.url.appendingPathComponent($0) } }
    
    func extract(to url: URL? = nil) -> R<Void> {
        guard let dstURL = url ?? self.url.maybeSuccess else {
            return .wtf("can't resolve URL for Blob \(oid.oidShort)")
        }
        
        return data | { dstURL.write(data: $0).asVoid }
    }
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
