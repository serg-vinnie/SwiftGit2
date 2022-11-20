
import Foundation
import Essentials

extension RepoID {
    struct Tree {
        
    }
}

class CacheStorage<Agent: CacheStorageAgent> {
    var roots = [Agent : Agent.RootStorage]()
    var items = [Agent : Agent.Storage]()
    
    func add(root: Agent) {
        roots[root] = root.rootStorage
        
        for item in root.flatTree {
            items[item] = item.storage
        }
    }
}

protocol CacheStorageAgent : Hashable {
    associatedtype RootStorage
    associatedtype Storage
    
    var flatTree    : [Self]        { get }
    
    var rootStorage : RootStorage   { get }
    var storage     : Storage       { get }
}
