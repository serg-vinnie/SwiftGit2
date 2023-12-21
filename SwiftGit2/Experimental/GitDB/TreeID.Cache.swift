
import Foundation
import Essentials

public extension TreeID {
    var cache : R<TreeID.Cache> {
        entries | { $0 | { $0.asCache } } | { TreeID.Cache(tree: self, entries: $0) }
    }
    
    struct Cache {
        public let tree : TreeID
        public let entries : [TreeID.Cache.Entry]
    }
}

public extension TreeID.Entry {
    var children : R<[TreeID.Entry]> { TreeID(repoID: self.treeID.repoID, oid: self.oid).entries }
    
    var asCache : R<TreeID.Cache.Entry> {
        if self.kind == .tree {
            return children | { $0 | { $0.asCache } } | { TreeID.Cache.Entry(oid: self.oid, name: self.name, children: $0) }
        }
        
        return .success(TreeID.Cache.Entry(oid: self.oid, name: self.name, children: nil))
    }
}

public extension TreeID.Cache {
    struct Entry : Identifiable {
        public let oid : OID
        public let name : String
        public let children : [TreeID.Cache.Entry]?
        
        public var id : OID { oid }
    }
}
