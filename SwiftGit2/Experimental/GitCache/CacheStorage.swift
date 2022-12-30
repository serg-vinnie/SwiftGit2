
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
        //defer {
            
        //}
        
        if let old = flatTrees[root] {
            let upd = Update(old: old, new: new)
            
            for item in upd.removed {
                items[item] = nil
            }
            
            flatTrees[root] = new
            
            for item in upd.inserted {
                items[item] = item.storageFactory
            }
            return upd
        } else {
            flatTrees[root] = new
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
    
    public func storage(for agent: Agent) -> Agent.Storage {
        if let stor = items[agent] {
            return stor
        }
        update(root: agent)
        if let stor = items[agent] {
            return stor
        } else {
            let stor = agent.storageFactory
            items[agent] = stor
            return stor
        }
    }
    
    public func rootStorage(for agent: Agent) -> Agent.RootStorage {
        if let root = roots[agent] {
            return root
        }
        
        for (key,tree) in flatTrees {
            if tree.contains(agent) {
                if let root = roots[key] {
                    return root
                }
            }
        }
        
        update(root: agent)
        if let root = roots[agent] {
            return root
        } else {
            let stor = agent.rootStorageFactory
            roots[agent] = stor
            return stor
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
    
    var rootStorageFactory : RootStorage   { get }
    var storageFactory     : Storage       { get }
}
