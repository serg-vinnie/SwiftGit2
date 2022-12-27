import Foundation
import Clibgit2
import Essentials

public struct GitCommitBasicInfo {
    public let id : CommitID
    public let author : GitSignature
    public let commiter : GitSignature
    public let tree : OID
    public let parents : [OID]
    
    public let summary     : String
    public let body        : String
    public let description : String
    public let time        : Date
    
    init(id: CommitID, commit: Commit, parents: [OID]) {
        self.id             = id
        self.author         = GitSignature(commit.author)
        self.commiter       = GitSignature(commit.commiter)
        self.tree           = commit.treeOID
        self.parents        = parents
        self.summary        = commit.summary
        self.body           = commit.body
        self.description    = commit.description
        self.time           = commit.time
    }
}

let cacheLock = UnfairLock()
var commitInfo = [RepoID:[OID:GitCommitBasicInfo]]()
internal extension CommitID {
    func saveCache(info: GitCommitBasicInfo) {
        cacheLock.locked {
            if !commitInfo.keys.contains(repoID) {
                commitInfo[repoID] = [OID:GitCommitBasicInfo]()
                commitInfo[repoID]?.reserveCapacity(1000)
            }
            
            if let info = self.basicInfo.maybeSuccess {
                commitInfo[repoID]?[oid] = info
            }
        }
    }
}


public extension CommitID {
    var basicInfoCache : GitCommitBasicInfo? {
        if let info = commitInfo[repoID]?[oid] {
            return info
        }
        if let info = self.basicInfo.maybeSuccess {
            saveCache(info: info)
            return info
        }
        return nil
    }
    
    var basicInfo : R<GitCommitBasicInfo> {
        withCommit { c in
            c.parents()
                | { $0.map { $0.oid } }
                | { GitCommitBasicInfo(id: self, commit: c, parents: $0) }
        }
    }
}

public extension GitCommitBasicInfo {
    var isAuthorEqualsCommitter : Bool {
        author.name == commiter.name &&
        author.email == commiter.email &&
        author.when == commiter.when
    }
}

final class UnfairLock {
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    init() {
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deallocate()
    }

    func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try f()
    }
}
