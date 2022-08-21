
import Foundation
import Essentials

public struct ReferenceCache : Identifiable {
    public var id: String { referenceID.id }
    
    public let referenceID: ReferenceID
    public let cache: GitRefCache
    
    init( _ ref: ReferenceID, cache: GitRefCache) {
        self.referenceID = ref
        self.cache  = cache
    }
}

public extension ReferenceCache {
    var isHead : Bool {
        if self.referenceID.isBranch {
            return self.cache.HEAD?.referenceID == self.referenceID
        } else {
            return self.cache.remoteHEADs.values.contains { $0?.referenceID == self.referenceID }
        }
        
    }
    
    var upstream : ReferenceCache? {
        if let upstrm = self.cache.upstreams.a2b[self.referenceID.name] {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: upstrm)
            return ReferenceCache(refID, cache: self.cache)
        }
        return nil
    }
    var downstream : ReferenceCache? {
        if let downstrm = self.cache.upstreams.b2a[self.referenceID.name] {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: downstrm)
            return ReferenceCache(refID, cache: self.cache)
        }
        return nil
    }
    
    var counterpart : ReferenceCache? {
        if let item = self.cache.upstreams.counterpart(self.referenceID.name) {
            let refID = ReferenceID(repoID: self.referenceID.repoID, name: item)
            return ReferenceCache(refID, cache: self.cache)
        }
        return nil
    }
}

extension ReferenceCache : Hashable {
    public static func == (lhs: ReferenceCache, rhs: ReferenceCache) -> Bool {
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
