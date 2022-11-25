
import Foundation
import Essentials

extension RepoID {
    struct Tree {
        
    }
}

public class CacheStorage<Agent: CacheStorageAgent> {
    public private(set) var roots     = [Agent : Agent.RootStorage]()
    public private(set) var items     = [Agent : Agent.Storage]()
    public private(set) var flatTrees = [Agent : Set<Agent>]()
    
    public init() {}
    
    public func update(root: Agent) {
        if !roots.keys.contains(root) {
            roots[root] = root.rootStorage
        }
        
        let newList = root.flatTree
        let new = Set(newList)
        defer {
            flatTrees[root] = new
        }
        
        if let old = flatTrees[root] {
            for item in old.subtracting(new) {
                items[item] = nil
            }
            
            for item in new.subtracting(old) {
                items[item] = item.storage
            }
        } else {
            for item in newList {
                items[item] = item.storage
            }
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
