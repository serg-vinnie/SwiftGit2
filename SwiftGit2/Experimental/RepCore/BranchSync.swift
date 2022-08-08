
import Foundation
import Essentials

struct BranchSync  {
    let our : ReferenceID
    let their : ReferenceID
    let push  : [OID]
    let pull  : [OID]
    
    init(our: ReferenceID, their: ReferenceID, push: [OID], pull: [OID]) {
        self.our    = our
        self.their  = their
        self.push   = push
        self.pull   = pull
    }
    
    static func with(our: ReferenceID, their: ReferenceID) -> R<BranchSync> {
        if our.repoID != their.repoID { return .wtf("BranchSync: references from different repositories") }
        
        let push = our.repoID.repo | { $0.oids(our: our.name, their: their.name) }
        let pull = our.repoID.repo | { $0.oids(our: their.name, their: our.name) }
        
        return combine(push, pull).map  { BranchSync(our: our, their: their, push: $0, pull: $1) }
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
