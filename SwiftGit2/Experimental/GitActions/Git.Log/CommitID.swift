
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
        return .success(GitCommitInfo(id: self))
    }
}
