
import Foundation
import Essentials

public struct Module {
    public let url : URL
    public let exists : Bool
    public let subModules : [String:Module]
}

public extension Repository {
    var asModule : R<Module> {
        directoryURL | { Module(url: $0, exists: true, subModules: [:]) }
    }
    
    static func module(at url: URL) -> R<Module> {
        guard Repository.exists(at: url) else {
            return .success(Module(url: url, exists: false, subModules: [:]))
        }
        return .success(Module(url: url, exists: true, subModules: [:]))
    }
}
