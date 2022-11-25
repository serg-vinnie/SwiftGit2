
import Foundation
import Essentials
import OrderedCollections
import Parsing

public struct SubmoduleID : Hashable {
    let repoID : RepoID
    let name: String
    
    var url : URL { repoID.url.appendingPathComponent(name) }
}

let gitdirFileParser = Parse {
    StartsWith("gitdir:")
    Whitespace(.all)
    Rest()
}

extension String {
    var parseGitDir : R<String> {
        do {
            let content = try gitdirFileParser.parse(self)
            return .success(String(content))
        } catch {
            return .failure(error)
        }
    }
}


public extension SubmoduleID {
    var dbPath : R<String> {
        let fullURL = url.appendingPathComponent(".git")
        guard fullURL.exists else { return .wtf("not exist: \(fullURL.path)") }
        
        if fullURL.isDirectory {
            return .success(fullURL.path)
        } else {
            return fullURL.readToString
                | { $0.parseGitDir }
                | { URL(string: $0, relativeTo: url)?.path  }
                | { $0.asNonOptional }
        }
    }
//    var submodule : R<Submodule> {
//        repoID.repo | { $0.submoduleLookup(named: name) }
//    }
    
    func update(auth: Auth) -> R<Void> {
        update(options: SubmoduleUpdateOptions(fetch: FetchOptions(auth: auth)))
    }
    
    func update(options: SubmoduleUpdateOptions) -> R<Void> {
        repoID.repo | {
            $0.submoduleLookup(named: name) | { $0.update(options: options, init: true) }
        }
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
