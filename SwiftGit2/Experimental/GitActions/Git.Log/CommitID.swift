
import Foundation
import Essentials

public struct CommitID {
    let repoID: RepoID
    let oid   : OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}

extension CommitID {
    var info : R<GitCommitInfo> {
        repoID.repo
            | { $0.deltas(target: .commit(oid)) }
            | { GitCommitInfo(id: self, deltas: $0) }
    }
}
