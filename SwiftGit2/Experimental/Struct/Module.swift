
import Foundation
import Essentials

public struct Module : CustomStringConvertible {
    public let url : URL
    public let exists : Bool
    public let subModules : [String:Module?]
    
    static func from(submodule: Submodule) -> R<Module> {
        let url = submodule.absURL
        
        if submodule.repoExist() {
            return combine(url, submodule.repo()) | { url, repo in
                repo.subModules | { Module(url: url, exists: true, subModules: $0) }
            }
        } else {
            return url | { Module(url: $0, exists: false, subModules: [:]) }
        }
    }
    
    public var description: String { "| M: " + url.lastPathComponent + " \(subModules) |" }
}



public extension Repository {
    var asModule : R<Module> {
        combine(directoryURL,subModules) | { Module(url: $0, exists: true, subModules: $1) }
    }
    
    var subModules : R<[String:Module?]> {
        return submodules() | { $0.asDictionary }
    }
    
    static func module(at url: URL) -> R<Module> {
        guard Repository.exists(at: url) else {
            return .success(Module(url: url, exists: false, subModules: [:]))
        }
        return .success(Module(url: url, exists: true, subModules: [:]))
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
        Module.from(submodule: self)
    }
}
