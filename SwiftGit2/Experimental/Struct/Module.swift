
import Foundation
import Essentials
import OrderedCollections


// TODO: fix detached head
public struct Module : CustomStringConvertible {
    public let url : URL
    public let exists : Bool
    public var recurse : OrderedDictionary<String,Module?> {
        var result = OrderedDictionary<String,Module?>()
        result[self.url.lastPathComponent] = self
        for item in subModulesRecursive {
            result[item.key] = item.value
        }
        return result //.merging(subModulesRecursive) { a, b in a }
    }
    public let subModules : OrderedDictionary<String,Module?>
    public var subModulesRecursive : OrderedDictionary<String,Module?> {
        var results = OrderedDictionary<String,Module?>()
        
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
    
    public func updateSubModules() -> R<()> {
        .notImplemented("updateSubModules")
    }
}

public extension Repository {
    var asModule : R<Module> {
        combine(directoryURL,subModules) | { Module(url: $0, exists: true, subModules: $1) }
    }
    
    var subModules : R<OrderedDictionary<String,Module?>> {
        return submodules() | { $0.asOrderedDictionary }
    }
    
    static func module(at url: URL) -> R<Module> {
        if Repository.exists(at: url) {
            return Repository.at(url: url) | { $0.asModule }
        }
        return .success(Module(url: url, exists: false, subModules: [:]))
    }
}

private extension Array where Element == Submodule {
    var asOrderedDictionary : OrderedDictionary<String,Module?> {
        self.toOrderedDictionary(key: \.name) { submodule in
            try? submodule.asModule.get()
        }
    }
}

private extension Submodule {
    var asModule : R<Module> {
        if repoExist() {
            return combine(absURL, repo()) | { url, repo in
                repo.subModules | { Module(url: url, exists: true, subModules: $0) }
            }
        } else {
            return absURL | { Module(url: $0, exists: false, subModules: [:]) }
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
