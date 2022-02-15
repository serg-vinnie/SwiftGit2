
import Foundation
import Essentials


// TODO: fix detached head
public struct Module : CustomStringConvertible {
    public let url : URL
    public let exists : Bool
    public let headIsUnborn : Bool
    public let subModules : [String:Module?]
        
    public var description: String { "| M(\(exists) \(headIsUnborn): " + url.lastPathComponent + " \(subModules) |" }
    
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
        combine(directoryURL,subModules) | { Module(url: $0, exists: true, headIsUnborn: self.headIsUnborn, subModules: $1) }
    }
    
    var subModules : R<[String:Module?]> {
        return submodules() | { $0.asDictionary }
    }
    
    static func module(at url: URL) -> R<Module> {
        if Repository.exists(at: url) {
            return Repository.at(url: url) | { $0.asModule }
        }
        return .success(Module(url: url, exists: false, headIsUnborn: false, subModules: [:]))
    }
}

private extension Array where Element == Submodule {
    var asDictionary : [String : Module?] {
        self.toDictionary(key: \.name) { submodule in
            try? submodule.asModule.get()
        }
    }
}

private extension Submodule {
    var asModule : R<Module> {
        if repoExist() {
            return combine(absURL, repo()) | { url, repo in
                repo.subModules | { Module(url: url, exists: true, headIsUnborn: repo.headIsUnborn, subModules: $0) }
            }
        } else {
            return absURL | { Module(url: $0, exists: false, headIsUnborn: false, subModules: [:]) }
        }
    }
}
