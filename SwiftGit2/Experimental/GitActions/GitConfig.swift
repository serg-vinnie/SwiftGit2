
import Foundation
import Clibgit2
import Essentials

public struct GitConfig {
    let repoID : RepoID
    
    public init(_ repoID: RepoID) {
        self.repoID = repoID
    }
    
    public var entries : R<[ConfigEntry]> {
        let repo = repoID.repo
        let config = repo | { $0.config }
        return config | { $0.iterator } | { $0.entries }
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
