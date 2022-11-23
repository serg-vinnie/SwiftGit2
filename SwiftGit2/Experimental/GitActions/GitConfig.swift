
import Foundation
import Clibgit2
import Essentials

public struct GitConfig {
    let repoID : RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
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
        
        return git_try("git_config_multivar_iterator_new") {
            git_config_multivar_iterator_new(&iterator, self.pointer, "", "")
        } | { _ in iterator.asNonOptional } | { ConfigIterator($0) }
    }
    
    var entries : R<[String]> {
//        git_config_iterator *iter;
//        git_config_entry *entry;
//
//        int error = git_config_multivar_iterator_new(&iter, cfg,
//            "core.gitProxy", "regex.*");
//        while (git_config_next(&entry, iter) == 0) {
//          /* … */
//        }
//        git_config_iterator_free(iter);
        return .notImplemented
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
    
    var entries : [String] {
        var result = [String]()
        
        forEach { entry in
            result.append(String(cString: entry.name))
        }
        
        return result
    }
}
