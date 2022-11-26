
import Foundation
import Essentials

extension RepoID {
    struct Tree {
        public private(set) var items        = Swift.Set<String>()
        public private(set) var childrenOf   = [String:Swift.Set<String>]()
        public private(set) var parentOf     = [String:String]()

    }
}

public class CacheStorage<Agent: CacheStorageAgent> {
    public private(set) var roots     = [Agent : Agent.RootStorage]()
    public private(set) var items     = [Agent : Agent.Storage]()
    public private(set) var flatTrees = [Agent : Set<Agent>]()
    
    public init() {}
    
    @discardableResult
    public func update(root: Agent) -> Update {
        if !roots.keys.contains(root) {
            roots[root] = root.rootStorage
        }
        
        let newList = root.flatTree
        let new = Set(newList)
        defer {
            flatTrees[root] = new
        }
        
        if let old = flatTrees[root] {
            let upd = Update(old: old, new: new)
            
            for item in upd.removed {
                items[item] = nil
            }
            
            for item in upd.inserted {
                items[item] = item.storage
            }
            
            return upd
        } else {
            for item in newList {
                items[item] = item.storage
            }
            
            return Update(old: [], new: new)
        }
    }
    
    public struct Update {
        public let inserted : Set<Agent>
        public let removed : Set<Agent>
        
        init(old: Set<Agent>, new: Set<Agent>) {
            self.inserted = new.subtracting(old)
            self.removed = old.subtracting(new)
        }
    }
}

public protocol CacheStorageAgent : Hashable {
    associatedtype RootStorage
    associatedtype Storage
    
    var flatTree    : [Self]        { get }
    
    var rootStorage : RootStorage   { get }
    var storage     : Storage       { get }
}
