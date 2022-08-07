
import Foundation
import Essentials

public final class GitRefCache {
    let repoID : RepoID
    public private(set) var local  : [ReferenceCache] = []
    public private(set) var remote : [String:[ReferenceCache]] = [:]
    public private(set) var tags   : [ReferenceCache] = []
    
    public private(set) var HEAD   : ReferenceCache?
    
    lazy var upstreams : OneOnOne = { local.upstreams() }()
    
    init(repoID: RepoID, local: [ReferenceID], remote: [ReferenceID], tags: [ReferenceID]) {
        self.repoID = repoID
        self.local  = local.map  { ReferenceCache($0, cache: self) }
        self.remote = remote.asCacheDic(cache: self)
        self.tags   = tags.map   { ReferenceCache($0, cache: self) }
        self.HEAD   = (repoID.repo | { $0.HEAD() }
                                   | { ReferenceCache(ReferenceID(repoID: repoID, name: $0.nameAsReference), cache: self) }
                       ).maybeSuccess
    }
    
    public static func from(repoID: RepoID) -> R<GitRefCache> {
        let local  = repoID.references(.local)
        let remote = repoID.references(.remote)
        let tags   = repoID.references(.tag)
        
        return combine(local, remote, tags)
            .map { GitRefCache(repoID: repoID, local: $0, remote: $1, tags: $2) }
    }
    
    public static func empty(_ repoID: RepoID?) -> GitRefCache {
        GitRefCache(repoID: repoID ?? RepoID(path: ""), local: [], remote: [], tags: [])
    }
}


extension Array where Element == ReferenceID {
    func asCacheDic(cache: GitRefCache) -> [String:[ReferenceCache]] {
        var dic = [String:[ReferenceCache]]()
        
        for ref in self {
            guard let remote = ref.remote else { continue }
            
            if dic.keys.contains(remote) {
                dic[remote]!.append(ReferenceCache(ref, cache: cache))
            } else {
                dic[remote] = [ReferenceCache(ref, cache: cache)]
            }
        }
        
        return dic
    }
}

extension Array where Element == ReferenceCache {
    func upstreams() -> OneOnOne {
        let arr = self.map { r in (r.referenceID.name, r.referenceID.upstream1Name) }
            .filter { $0.1 != nil }
            .map { ($0.0,$0.1!)}
        return OneOnOne(arr)
    }
}

extension ReferenceID {
    var upstream1Name : String? {
        return (repoID.repo.flatMap{ $0.reference(name: name) | { $0.upstreamName() } }).maybeSuccess
        //return name.maybeSuccess
    }
}
