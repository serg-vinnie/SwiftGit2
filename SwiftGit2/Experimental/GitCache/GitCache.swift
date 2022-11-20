
import Foundation

class GitCache {
    var roots = [RepoID:RootRepoCache]()
    var repos = [RepoID:RepoCache]()
}
