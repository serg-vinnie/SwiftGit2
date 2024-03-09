
import Foundation
import Essentials

public extension TreeID {
    var cache : R<TreeID.Cache> {
        entries | { $0 | { $0.asCacheEntry() } } | { TreeID.Cache(tree: self, entries: $0) }
    }
    
    var cacheTrees : R<TreeID.Cache> {
        entries | { $0.compactMap { $0.asCacheTree(path: nil).maybeSuccess } } | { TreeID.Cache(tree: self, entries: $0) }
    }
    
    struct Cache {
        public let tree : TreeID
        public let entries : [TreeID.Cache.Entry]
        public var allOIDs : [OID] { entries.map { $0.oid } + entries.compactMap { $0.children }.flatMap { $0 }.map { $0.oid } }
    }
}

public extension TreeID.Entry {
    var children : R<[TreeID.Entry]> { TreeID(repoID: self.treeID.repoID, oid: self.oid).entries }
    
    fileprivate func asCacheEntry(path: String? = nil) -> R<TreeID.Cache.Entry> {
        if self.kind == .tree {
            return children | { $0 | { $0.asCacheEntry() } } | { TreeID.Cache.Entry(oid: self.oid, name: self.name, path: path, children: $0) }
        }
        
        return .success(TreeID.Cache.Entry(oid: self.oid, name: self.name, path: path, children: nil))
    }
    
    func asCacheTree(path: String? = nil) -> R<TreeID.Cache.Entry> {
        if self.kind == .tree {
            return children | { $0.compactMap { $0.asCacheTree(path: path).maybeSuccess } } | { TreeID.Cache.Entry(oid: self.oid, name: self.name, children: $0) }
        }
        
        return .wtf("not a tree")
    }
}

public extension TreeID.Cache {
    struct Entry : Identifiable {
        public let oid : OID
        public let name : String
        public let path : String?
        public let children : [TreeID.Cache.Entry]?
        
        public var id : OID { oid }
        

        init(oid: OID, name: String, path: String? = nil, children: [TreeID.Cache.Entry]?) {
            self.oid = oid
            self.name = name
            self.path = path
            self.children = children
        }
    }
}

extension String {
    func appendingPath(component: String) -> String {
        if self.hasSuffix("/") {
            return self + component.trimStart("/")
        }
        return self + "/" + component.trimStart("/")
    }
}

