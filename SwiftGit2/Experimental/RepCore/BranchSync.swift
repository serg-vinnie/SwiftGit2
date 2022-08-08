
import Foundation
import Essentials

struct BranchSync  {
    let our : ReferenceID
    let their : ReferenceID
    let base  : OID
    
    var push : R<[OID]> { our.repoID.repo | { $0.oids(our: our.name, their: their.name) } }
    var pull : R<[OID]> { our.repoID.repo | { $0.oids(our: their.name, their: our.name) } }
    
    init(our: ReferenceID, their: ReferenceID, base: OID) {
        self.our    = our
        self.their  = their
        self.base   = base
    }
    
    static func with(our: ReferenceID, their: ReferenceID) -> R<BranchSync> {
        if our.repoID != their.repoID { return .wtf("BranchSync: references from different repositories") }
        
        let ourOID = our.targetOID
        let theirOID = their.targetOID
        let repo = our.repoID.repo
        
        return combine(repo,ourOID, theirOID) | { $0.mergeBase(one: $1, two: $2) } | { BranchSync(our: our, their: their, base:$0) }
        
        //let push = our.repoID.repo | { $0.oids(our: our.name, their: their.name) }
        //let pull = our.repoID.repo | { $0.oids(our: their.name, their: our.name) }
    }
    
    func conflicted() -> R<Bool> {
//        let ourOID   = ourLocal.targetOID
//        let theirOID = ourLocal.upstream()       | { $0.targetOID }
//        let baseOID  = combine(ourOID, theirOID) | { self.mergeBase(one: $0, two: $1) }
//
//        let message = combine(theirReference, baseOID)
//            | { their, base in "MERGE [\(their.nameAsReferenceCleaned)] & [\(ourLocal.nameAsReferenceCleaned)] | BASE: \(base)" }
//
//        let ourCommit   = ourOID   | { self.commit(oid: $0) }
//        let theirCommit = theirOID | { self.commit(oid: $0) }
//
//        let parents = combine(ourCommit, theirCommit) | { [$0, $1] }
//
//        let branchName = ourLocal.nameAsReference
//
//        return [ourOID, theirOID, baseOID]
//            .flatMap { $0.tree(self) }
//            .flatMap { self.merge(our: $0[0], their: $0[1], ancestor: $0[2], options: options.mergeOptions) } // -> Index
//            .if(\.hasConflicts,
        return .notImplemented
    }
}


internal extension Repository {
    func oids(our pushRef: String, their hideRef: String) -> Result<[OID], Error> {
        Revwalk.new(in: self)
            | { $0.push(ref: pushRef) }
            | { $0.hide(ref: hideRef) }
            | { $0.all() }
    }
}

