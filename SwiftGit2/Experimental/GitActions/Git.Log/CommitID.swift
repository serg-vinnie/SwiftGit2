
import Foundation
import Essentials

public struct CommitID {
    let repoID: RepoID
    let oid   : OID
    
    var commit : R<Commit> { self.repoID.repo | { $0.commit(oid: self.oid) } }
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}
