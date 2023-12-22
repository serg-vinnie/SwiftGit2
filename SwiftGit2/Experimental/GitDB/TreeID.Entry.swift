
import Foundation
import Essentials
import Clibgit2
import Foundation

public extension TreeID {
    struct Entry : CustomStringConvertible {
        enum Kind : String {
            case blob
            case tree
            case wtf
        }
        
        let treeID: TreeID
        let name: String
        let oid: OID
        let kind: Kind
        
        public var description: String { "\(oid.oidShort) \(name) \(kind)" }
    }
    
    struct IteratorEntry {
        let treeID: TreeID
        let url: URL
        let oid: OID
        let name: String
        var fullURL: URL { url.appendingPathComponent(name) }
    }
}

extension TreeID.IteratorEntry {
    var data : R<Data> { treeID.repoID.repo | { $0.blob(oid: oid) | { $0.asData } } }
    
    func extract() -> R<Void> {
        let treeID = treeID.repoID.repo | { $0.treeLookup(oid: oid) | { _ in TreeID(repoID: self.treeID.repoID, oid: self.oid) }}
        if let tree = treeID.maybeSuccess {
            return fullURL.makeSureDirExist() | { _ in tree.extract(at: self.fullURL) }
        }
        
        return data | { $0.write(url: self.fullURL).asVoid }
    }
}
