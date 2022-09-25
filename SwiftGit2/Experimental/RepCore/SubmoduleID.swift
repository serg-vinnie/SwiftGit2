
import Foundation
import Essentials
import OrderedCollections

public struct SubmoduleID : Hashable {
    let repoID : RepoID
    let name: String
}

public extension SubmoduleID {
    var submodule : R<Submodule> {
        repoID.repo | { $0.submoduleLookup(named: name) }
    }
    
    func update(auth: Auth) -> R<Void> {
        update(options: SubmoduleUpdateOptions(fetch: FetchOptions(auth: auth)))
    }
    
    func update(options: SubmoduleUpdateOptions) -> R<Void> {
        submodule | { $0.update(options: options) }
    }
}
public extension GitModule {
    struct Progress {
        public let total : Int
        public let exist : Int
    }
}

public extension GitModule {
    func next(options: SubmoduleUpdateOptions) -> R<Progress> {
        if let submodule = firstUnInited {
            return submodule.update(options: options) | { repoID.module } | { $0.progress }
        } else {
            return                                        repoID.module   | { $0.progress }
        }
    }
    
    var firstUnInited : SubmoduleID? {
        for (key,value) in idsRecursive {
            if value == nil {
                return key
            }
        }
        return nil
    }
    
    var idsRecursive : OrderedDictionary<SubmoduleID,GitModule?> {
        var results = OrderedDictionary<SubmoduleID,GitModule?>()
        
        for item in subModules {
            let subID = SubmoduleID(repoID: self.repoID, name: item.key)
            results[subID] = item.value
            if let module = item.value {
                for item in module.idsRecursive {
                    results[item.key] = item.value
                }
            }
        }
        
        return results
    }

}
