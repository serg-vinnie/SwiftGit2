
import Foundation
import Essentials
import OrderedCollections

// TODO: fix detached head
public struct GitModule : CustomStringConvertible {
    public var repoID : RepoID { RepoID(url: url) }
    public let url : URL
    public let exists : Bool
    
    public var childrenTargets : R<[CommitID]> {
        repoID.repo
        | { $0.children_URLs_OIDs() }
        | { $0.compactMapValues { $0 } }
        | { $0.map { CommitID(repoID: $0.key, oid: $0.value) } }
    }
    
    public var progress : Progress {
        let all = subModulesRecursive
        return Progress(total: all.count, exist: all.values.compactMap { $0 }.count )
    }
    
    public var recurse : OrderedDictionary<String,GitModule?> {
        var result = OrderedDictionary<String,GitModule?>()
        result[self.url.lastPathComponent] = self
        for item in subModulesRecursive {
            result[item.key] = item.value
        }
        return result //.merging(subModulesRecursive) { a, b in a }
    }
    public let subModules : OrderedDictionary<String,GitModule?>
    public var subModulesRecursive : OrderedDictionary<String,GitModule?> {
        var results = OrderedDictionary<String,GitModule?>()
        
        for item in subModules {
            results[item.key] = item.value
            if let module = item.value {
                for item in module.subModulesRecursive {
                    results[item.key] = item.value
                }
            }
        }
        
        return results
    }
        
    public var description: String { "| M(\(exists)): " + url.lastPathComponent + " \(subModulesRecursive.count)" + " \(subModulesRecursive.map { "\(($0.value == nil) ? "." : "" )" + $0.key }) |" }
    
    public func removeSub(module: String) {
        _ = repoID.repo | { $0.submoduleLookup(named: module) } //| {  }
        
        /*
         
         # Remove the submodule entry from .git/config
         git submodule deinit -f path/to/submodule

         # Remove the submodule directory from the superproject's .git/modules directory
         rm -rf .git/modules/path/to/submodule

         # Remove the entry in .gitmodules and remove the submodule directory located at path/to/submodule
         git rm -f path/to/submodule
         
         */
    }
    
    public func addSub(module: String, remote: String, gitlink: Bool = true, options: SubmoduleUpdateOptions, signature: Signature) -> R<Void> {
        let canCommit = Repository.at(url: url) | { $0.status() } | { $0.count == 0 }
        
        let operation = Repository.at(url: url)
            .flatMap { repo in
                repo.add(submodule: module, remote: remote, gitlink: true)
                    .flatMap { $0.cloned(options: options) }
                    .flatMap { $0.add_finalize() }
            }
        
        let msg = "Submodule \(module) was added"
        
        return combine(canCommit, operation)
            .map { canCommit, _ in canCommit }
            .if(\.self, then: { _ in
                Repository.at(url: url) | { $0.stage(.all) } | { $0.commit(message: msg, signature: signature) } | { _ in () }
            }, else: { _ in
                    .success(())
            })
    }
    
    public func updateSubModules(options: SubmoduleUpdateOptions, `init`: Bool) -> R<()> {
        repoID.repo | {     // keep repository reference during work with submodules
            $0.submodules() | { $0 | { $0.update(options: options, init: `init`) } }
        } | { _ in () }
    }
}

/*
 
 let cloneOpt = SubmoduleUpdateOptions(fetch: fetch, checkout: checkout)
 let ret = self.update(options: cloneOpt, init: true)
 
 func updateSubmodules(a: TreeProgressAccum, auth: Auth) -> Channel<TreeProgressAccum,Void> {
     let duos = submodules() | { $0 | { Duo($0,self) } }
     
     return duos
         .flatMap { $0.flatMap { duo in duo.getSubmoduleAbsPath().map { (duo.submodule.headOID,$0,duo) } } }
         .map { $0.filter { oid, path, duo in !a.contains(oid: oid, at: path) } }
         .map { $0.map { $0.2 } }
         .flatMap { $0.foldr(a) { a, host in host.updateRecursive(a: a, auth: auth) } }
 }
 
 */

public extension Repository {
    var asModule : R<GitModule> {
        combine(directoryURL,subModules) | { GitModule(url: $0, exists: true, subModules: $1) }
    }
    
    var subModules : R<OrderedDictionary<String,GitModule?>> {
        return submodules() | { $0.asOrderedDictionary }
    }
    
    static func module(at url: URL) -> R<GitModule> {
        if Repository.exists(at: url) {
            return Repository.at(url: url) | { $0.asModule }
        }
        return .success(GitModule(url: url, exists: false, subModules: [:]))
    }
    
    internal func children_URLs_OIDs() -> R<[RepoID: OID?]> {
        let children = self.submodules() | { $0.map { ($0.path,$0.headOID) } }
        
        return combine(directoryURL, children)
            | { url, children in children.map { (RepoID(url: url.appendingPathComponent($0)),$1) } }
            | { $0.toDictionary(key: \.0) { $0.1 } }
    }
}

private extension Array where Element == Submodule {
    var asOrderedDictionary : OrderedDictionary<String,GitModule?> {
        self.toOrderedDictionary(key: \.name) { submodule in
            try? submodule.asModule.get()
        }
    }
}

private extension Submodule {
    var asModule : R<GitModule> {
        if repoExist() {
            return combine(absURL, repo()) | { url, repo in
                repo.subModules | { GitModule(url: url, exists: true, subModules: $0) }
            }
        } else {
            return absURL | { GitModule(url: $0, exists: false, subModules: [:]) }
        }
    }
}

public extension Sequence {
    func toOrderedDictionary<Key: Hashable, Value>(key: KeyPath<Element, Key>, block: (Element)->(Value)) -> OrderedDictionary<Key,Value> {
        var dic: OrderedDictionary<Key,Value> = [:]
        for element in self {
            dic[element[keyPath: key]] = block(element)
        }
        return dic
    }

}

extension OrderedDictionary where Key == String, Value == GitModule? {
    var asRepoIDs : [RepoID] {
        values.compactMap { $0?.repoID }
    }
}
