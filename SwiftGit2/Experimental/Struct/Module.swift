
import Foundation
import Essentials


// TODO: fix detached head
public struct Module : CustomStringConvertible {
    public let url : URL
    public let exists : Bool
    public let headIsUnborn : Bool
    public let subModules : [String:Module?]
        
    public var description: String { "| M(\(exists) \(headIsUnborn): " + url.lastPathComponent + " \(subModules) |" }
    
    public func addSub(module: String, remote: String, gitlink: Bool = true, options: SubmoduleUpdateOptions? = nil) -> R<Void> {
        let opt = options ?? SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.none)),
                                                    checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
        
        return Repository.at(url: url)
            .flatMap { $0.add(submodule: module, remote: remote, gitlink: true) }
            .flatMap { $0.clone(options: opt) }
            .flatMap { _ in Repository.at(url: url) }
            .flatMap { $0.submoduleLookup(named: module) }
            .flatMap { $0.add_finalize() }
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
