
import Foundation
import Essentials

public class CacheStorage<Agent: CacheStorageAgent> {
    public private(set) var roots     = [Agent : Agent.RootStorage]()
    public private(set) var items     = [Agent : Agent.Storage]()
    public private(set) var flatTrees = [Agent : Set<Agent>]()
    
    public init() {}
    
    @discardableResult
    public func update(root: Agent) -> Update {
        if !roots.keys.contains(root) {
            roots[root] = root.rootStorageFactory
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
                items[item] = item.storageFactory
            }
            
            return upd
        } else {
            for item in newList {
                items[item] = item.storageFactory
            }
            
            return Update(old: [], new: new)
        }
    }
    
    public func rootOf(_ agent: Agent) -> Agent {
        if roots.keys.contains(agent) {
            return agent
        }
        
        for (root, children) in flatTrees {
            if children.contains(agent) {
                return root
            }
        }

        return agent
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
    
    var rootStorageFactory : RootStorage   { get }
    var storageFactory     : Storage       { get }
}
