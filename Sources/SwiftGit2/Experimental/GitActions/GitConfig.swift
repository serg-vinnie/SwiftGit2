
import Foundation
import Clibgit2
import Essentials

public struct GitConfigDefault {
    public init() { }
    
    public static var url : URL { URL.userHome.appendingPathComponent(".gitconfig") }
    
    public var entries : R<[ConfigEntry]> {
        config | { config in config.iterator | { $0.entries } }
    }
    
    public func entry(name: String) -> R<ConfigEntry> {
        entries | { $0.first { $0.name == name }.asNonOptional }
    }
    
    public func exist(name: String) -> R<Bool> {
        entries | { $0.first { $0.name == name } != nil }
    }
    
    public func set(name: String, value: String) -> R<Void> {
        config | { $0.set(name: name, value: value) }
    }
    
    var config : R<Config> {
        git_instance(of: Config.self, "git_config_open_default") { pointer in
            git_config_open_default(&pointer)
        }
    }
}

public struct GitConfig {
    let repoID : RepoID
    
    public init(_ repoID: RepoID) {
        self.repoID = repoID
    }
    
    public var entries : R<[ConfigEntry]> {
        repoID.repo | { repo in repo.config | { config in config.iterator | { $0.entries } } }
    }
    
    public func delete(entry name: String) -> R<Void> {
        repoID.repo | { repo in repo.config | { config in config.delete(entry: name) } }
    }
    
}

extension Repository {
    var config : R<Config> {
        git_instance(of: Config.self, "git_repository_config") { pointer in
            git_repository_config(&pointer, self.pointer)
        }
    }
}

extension Config {
    var iterator : R<ConfigIterator> {
        var iterator : UnsafeMutablePointer<git_config_iterator>?
        
        return git_try("git_config_iterator_new") {
            git_config_iterator_new(&iterator, self.pointer) //, "submodule \"sub_repo\".url", nil /* "regex.*" */)
        } | { _ in iterator.asNonOptional } | { ConfigIterator($0) }
    }
    
    func delete(entry name: String) -> R<Void> {
        git_try("git_config_delete_entry") {
            git_config_delete_entry(self.pointer, name)
        }
    }
    
    func set(name: String, value: String) -> R<Void> {
        git_try("git_config_set_string") {
            git_config_set_string(self.pointer, name, value)
        }
    }
    
    func getPath(name: String) -> R<String> {
        var buf = git_buf(ptr: nil, asize: 0, size: 0)
        
        return git_try("git_config_get_path") {
            git_config_get_path(&buf, self.pointer, name)
        } | { Buffer(buf: buf).asString() }
    }
}

extension ConfigIterator {
    func forEach(_ block: (git_config_entry)->Void) {
        var config_entry : UnsafeMutablePointer<git_config_entry>?
        while (git_config_next(&config_entry, self.pointer) == 0) {
            if let next = config_entry?.pointee {
                block(next)
            }
        }
    }
    
    var entries : [ConfigEntry] {
        var result = [ConfigEntry]()
        
        forEach { entry in
            if let c = ConfigEntry(entry) {
                result.append(c)
            }
        }
        
        return result
    }
}
