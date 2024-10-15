
import Foundation
import Essentials
import Clibgit2
import Foundation

public extension TreeID {
    struct Entry : CustomStringConvertible, Identifiable, Hashable {
        public var id: OID { oid }
        
        public enum Kind : String {
            case blob
            case tree
            case submodule
            case fake
        }
        
        public let treeID: TreeID
        public let name: String
        public let oid: OID
        public let kind: Kind
        
        public init(treeID: TreeID, name: String, oid: OID, kind: Kind) {
            self.treeID = treeID
            self.name = name
            self.oid = oid
            self.kind = kind
        }
        
        public var description: String { "\(oid.oidShort) \(name) \(kind)" }
        public var asTreeID : R<TreeID> {
            guard self.kind == .tree else { return .wtf("not a tree") }
            return .success(TreeID(repoID: treeID.repoID, oid: oid))
        }
        
        public var asBlobID : R<BlobID> {
            guard self.kind == .blob else { return .wtf("not a tree") }
            return .success(BlobID(repoID: treeID.repoID, oid: oid))
        }
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
