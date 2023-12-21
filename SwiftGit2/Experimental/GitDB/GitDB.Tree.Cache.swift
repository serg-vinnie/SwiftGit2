
import Foundation
import Essentials

public extension GitDB.Tree {
    var cache : R<GitDB.Tree.Cache> {
        entries | { $0 | { $0.asCache } } | { GitDB.Tree.Cache(tree: self, entries: $0) }
    }
    
    struct Cache {
        let tree : GitDB.Tree
        let entries : [GitDB.Tree.Cache.Entry]
    }
}

public extension GitDB.Tree.Entry {
    var children : R<[GitDB.Tree.Entry]> { GitDB.Tree(repoID: self.repoID , oid: self.oid).entries }
    
    var asCache : R<GitDB.Tree.Cache.Entry> {
        if self.kind == .tree {
            return children | { $0 | { $0.asCache } } | { GitDB.Tree.Cache.Entry(oid: self.oid, name: self.name, children: $0) }
        }
        
        return .success(GitDB.Tree.Cache.Entry(oid: self.oid, name: self.name, children: nil))
    }
}

public extension GitDB.Tree.Cache {
    struct Entry : Identifiable {
        public let oid : OID
        public let name : String
        public let children : [GitDB.Tree.Cache.Entry]?
        
        public var id : OID { oid }
    }
}
