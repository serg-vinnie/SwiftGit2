
import Foundation
import Essentials

public struct ReferenceEx : Identifiable, Equatable, Comparable {
    public var id: String { referenceID.id }
    
    public let referenceID: ReferenceID
    public let cache: GitRefCache
    
    init( _ ref: ReferenceID, cache: GitRefCache) {
        self.referenceID = ref
        self.cache  = cache
    }
    
    public static func < (lhs: ReferenceEx, rhs: ReferenceEx) -> Bool {
        guard let l = lhs.commitID?.basicInfoCache,
              let r = rhs.commitID?.basicInfoCache else { return false }
        
        return l.time > r.time
    }
}

public extension ReferenceEx {
    var commitID : CommitID? { cache.commit(for: referenceID) }
    
    var isHead : Bool {
        if self.referenceID.isBranch {
            return self.cache.HEAD?.referenceID == self.referenceID
        } else {
            return self.cache.remoteHEADs.values.contains { $0?.referenceID == self.referenceID }
        }
        
    }
    
    var upstream : ReferenceEx? {
        if let upstrm = self.cache.upstreams.a2b[self.referenceID.name] {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: upstrm)
            return ReferenceEx(refID, cache: self.cache)
        }
        return nil
    }
    var downstream : ReferenceEx? {
        if let downstrm = self.cache.upstreams.b2a[self.referenceID.name] {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: downstrm)
            return ReferenceEx(refID, cache: self.cache)
        }
        return nil
    }
    
    var counterpart : ReferenceEx? {
        if let item = self.cache.upstreams.counterpart(self.referenceID.name) {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: item)
            return ReferenceEx(refID, cache: self.cache)
        }
        return nil
    }
}

extension ReferenceEx : Hashable {
    public static func == (lhs: ReferenceEx, rhs: ReferenceEx) -> Bool {
        lhs.referenceID == rhs.referenceID
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.referenceID)
    }
}

struct OneOnOne {
    let a2b : [String:String]
    let b2a : [String:String]
    
    init(a2b : [String:String], b2a : [String:String]) {
        self.a2b = a2b
        self.b2a = b2a
    }
    
    init( _ map : [(String,String)]) {
        var a2b = [String:String]()
        var b2a = [String:String]()
        
        for (a,b) in map {
            a2b[a] = b
            b2a[b] = a
        }
        self.a2b = a2b
        self.b2a = b2a
    }
    
    func counterpart( _ id : String) -> String? {
        if let b = a2b[id] {
            return b
        }
        if let a = b2a[id] {
            return a
        }
        
        return nil
    }
    
    static var empty : OneOnOne { OneOnOne(a2b: [:], b2a: [:]) }
}

//struct OneOnMany {
//    let a2b : [String:[String]]
//    let b2a : [String:String]
//}

//--------------

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
