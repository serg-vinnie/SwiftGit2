
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
//        let _ = treeID.repoID.repo | { $0.anyObject(oid: self.oid) | { $0.extract() }}
        
        let treeID = treeID.repoID.repo | { $0.treeLookup(oid: oid) | { _ in TreeID(repoID: self.treeID.repoID, oid: self.oid) }}
        if let tree = treeID.maybeSuccess {
            return fullURL.makeSureDirExist() | { _ in tree.extract(at: self.fullURL) }
        }
        
        let _ = data | { $0.write(url: self.fullURL).asVoid }
        return .success(())
    }
}

extension AnyGitObject {
    func extract() -> R<Void> {
        
        switch self.type {
        case GIT_OBJECT_ANY: print("GIT_OBJECT_ANY")
        case GIT_OBJECT_INVALID: print("GIT_OBJECT_INVALID")
        case GIT_OBJECT_COMMIT: print("GIT_OBJECT_COMMIT")
        case GIT_OBJECT_TREE: print("GIT_OBJECT_TREE")
        case GIT_OBJECT_BLOB: print("GIT_OBJECT_BLOB")
        case GIT_OBJECT_TAG: print("GIT_OBJECT_TAG")
        case GIT_OBJECT_OFS_DELTA: print("GIT_OBJECT_OFS_DELTA")
        case GIT_OBJECT_REF_DELTA: print("GIT_OBJECT_REF_DELTA")
        default:
            break
        }
     
        return .notImplemented
    }
}
