
import Foundation
import Essentials

extension RepoID {
    struct Tree {
        
    }
}

class GitCache<Agent: CacheStorageAgent> {
    var roots = [Agent : Agent.RootStorage]()
    var repos = [Agent : Agent.Storage]()
    
    func add(root: Agent) {
//        guard let list = (rootID.module
//                          | { $0.recurse.filter { $0.value?.exists ?? false }.asRepoIDs }).maybeSuccess
//            else { return }
        
        //self.r
    }
}

//protocol Tree

protocol CacheStorageAgent : Hashable {
    associatedtype RootStorage
    associatedtype Storage
    
    var rootStorage : RootStorage { get }
    var storage : Storage { get }
}
