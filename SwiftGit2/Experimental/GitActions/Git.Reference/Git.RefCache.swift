
import Foundation
import Essentials
import SwiftUI

public final class GitRefCache {
    public let repoID : RepoID
    public private(set) var local  : [ReferenceEx] = []
    public private(set) var remote : [String:[ReferenceEx]] = [:]
    public private(set) var tags   : [ReferenceEx] = []
    
    public private(set) var HEAD   : ReferenceEx?
    public              let HEAD_OID : OID?
    public private(set) var remotes: GitRemotesList = [:]
    public private(set) var remoteHEADs: [String:ReferenceEx?] = [:]
    
    public private(set) var oids: [OID: Set<ReferenceID>] = [:]
    
    lazy var upstreams : OneOnOne = { local.upstreams() }()
    
    init(repoID: RepoID, list: [ReferenceID], remotes: GitRemotesList) {
        let head = ReferenceID(repoID: repoID, name: "HEAD")
        if let oid = head.targetOID.maybeSuccess {
            HEAD_OID = oid
        } else {
            HEAD_OID = nil
        }
        
        self.repoID = repoID
        self.remotes = remotes
        self.local  = list.filter { $0.isBranch }.map  { ReferenceEx($0, cache: self) }//.sorted()
        let list_remotes    = list.filter { $0.isRemote }
        self.remote         = list_remotes.asRemotesDic(cache: self)
        self.remoteHEADs    = list_remotes.asRemoteHEADsDic(cache: self)
        self.tags   = list.filter { $0.isTag    }.map   { ReferenceEx($0, cache: self) }//.sorted()
        self.HEAD   = (repoID.repo | { $0.HEAD() }
                                   | { ReferenceEx(ReferenceID(repoID: repoID, name: $0.nameAsReference), cache: self) }
                       ).maybeSuccess
        
        for ref in list {
            if let oid = ref.targetOID.maybeSuccess {
                if oids.keys.contains(oid) {
                    oids[oid]?.insert(ref)
                } else {
                    oids[oid] = [ref]
                }
            }
        }
        
        
        if let oid = head.targetOID.maybeSuccess {
            if oids.keys.contains(oid) {
                oids[oid]?.insert(head)
            } else {
                oids[oid] = [head]
            }
        }
    }
    
    public func find(refID: ReferenceID) -> ReferenceEx? {
        if refID.isBranch { return local.first { $0.referenceID == refID } }
        if refID.isRemote { return remote.values.flatMap { $0 }.first { $0.referenceID == refID }}
        if refID.isTag    { return tags.first { $0.referenceID == refID } }
        
        return nil
    }
    
    public static func from(repoID: RepoID) -> R<GitRefCache> {
        let list    = repoID.references
        let remotes = GitRemotes(repoID: repoID).list
        
        return combine(list, remotes)
            .map { GitRefCache(repoID: repoID, list: $0, remotes: $1) }
    }
    
    public static func empty(_ repoID: RepoID?) -> GitRefCache {
        GitRefCache(repoID: repoID ?? RepoID(path: ""), list: [], remotes: [:])
    }
    
    var commits = [ReferenceID:CommitID]()
    
    public func commit(for ref : ReferenceID) -> CommitID? {
        if let c = commits[ref] {
            return c
        }
        
        if let oid = ref.targetOID.maybeSuccess {
            let c = CommitID(repoID: repoID, oid: oid)
            commits[ref] = c
            return c
        }
        
        return nil
    }
}


extension Array where Element == ReferenceID {
    func asRemotesDic(cache: GitRefCache) -> [String:[ReferenceEx]] {
        var dic = [String:[ReferenceEx]]()
        
        for ref in self {
            guard let remote = ref.remote else { continue }
            guard ref.displayName != "HEAD" else { continue }
            
            if dic.keys.contains(remote) {
                dic[remote]!.append(ReferenceEx(ref, cache: cache))
            } else {
                dic[remote] = [ReferenceEx(ref, cache: cache)]
            }
        }
        
        return dic//.mapValues { $0.sorted() }
    }
    
    func asRemoteHEADsDic(cache: GitRefCache) -> [String:ReferenceEx] {
        var dic = [String:ReferenceEx]()
        
        for ref in self {
            guard let remote = ref.remote else { continue }
            guard ref.displayName == "HEAD" else { continue }
            guard let symbolicRef = ref.symbolic.maybeSuccess else { continue }
            
            dic[remote] = ReferenceEx(symbolicRef, cache: cache)
        }
        
        return dic
    }
}

extension Array where Element == ReferenceEx {
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

public extension Dictionary where Key == String, Value == ReferenceEx {
    var asList : [ReferenceEx] {
        compactMap { $0.value }
    }
}
