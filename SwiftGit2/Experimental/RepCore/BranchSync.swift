
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
    }
    
    var mergeIndex : R<Index> {
        let ourOID = our.targetOID
        let theirOID = their.targetOID
        let repo = our.repoID.repo
        
        return combine(repo, ourOID, theirOID)
            .flatMap { repo, our, their in repo.merge(our: our, their: their, base: self.base, options: MergeOptions()) }
    }
}

extension Repository {
    func merge(our: OID, their: OID, base: OID, options: MergeOptions) -> R<Index> {
        return [our, their, base]
            .flatMap { self.commit(oid: $0) | { $0.tree() } }
            .flatMap { self.merge(our: $0[0], their: $0[1], ancestor: $0[2], options: options) } // -> Index
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

