
import Foundation
import Essentials


struct ReferenceCache {
    public let referenceID: ReferenceID
    public let cache: GitRefCache
    
    init( _ ref: ReferenceID, cache: GitRefCache) {
        self.referenceID = ref
        self.cache  = cache
    }
}

public final class GitRefCache {
    let repoID : RepoID
    private(set) var local  : [ReferenceCache] = []
    private(set) var remote : [ReferenceCache] = []
    private(set) var tags   : [ReferenceCache] = []
    
    private(set) var HEAD   : ReferenceCache?
    
    init(repoID: RepoID, local: [ReferenceID], remote: [ReferenceID], tags: [ReferenceID]) {
        self.repoID = repoID
        self.local  = local.map { ReferenceCache($0, cache: self) }
        self.remote = remote.map { ReferenceCache($0, cache: self) }
        self.tags   = tags.map { ReferenceCache($0, cache: self) }
        self.HEAD   = (repoID.repo | { $0.HEAD() }
                                   | { ReferenceCache(ReferenceID(repoID: repoID, name: $0.nameAsReference), cache: self) }
                       ).maybeSuccess
    }
    
    func from(repoID: RepoID) -> R<GitRefCache> {
        let local  = repoID.references(.local)
        let remote = repoID.references(.remote)
        let tags   = repoID.references(.tag)
        
        return combine(local, remote, tags)
            .map { GitRefCache(repoID: repoID, local: $0, remote: $1, tags: $2) }
    }
}

extension ReferenceCache {
    var isHead : Bool { self.cache.HEAD?.referenceID == self.referenceID }
}
