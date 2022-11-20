
import Foundation
import Essentials

extension RepoID {
    struct Tree {
        
    }
}

public class CacheStorage<Agent: CacheStorageAgent> {
    public private(set) var roots = [Agent : Agent.RootStorage]()
    public private(set) var items = [Agent : Agent.Storage]()
    
    public func add(root: Agent) {
        roots[root] = root.rootStorage
        
        for item in root.flatTree {
            items[item] = item.storage
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
