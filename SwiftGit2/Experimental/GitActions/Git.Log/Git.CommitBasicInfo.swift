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
    public let description : String
    
    init(id: CommitID, commit: Commit, parents: [OID]) {
        self.id             = id
        self.author         = GitSignature(commit.author)
        self.commiter       = GitSignature(commit.commiter)
        self.tree           = commit.treeOID
        self.parents        = parents
        self.summary        = commit.summary
        self.description    = commit.description
    }
}

public extension CommitID {
    var basicInfo : R<GitCommitBasicInfo> {
        let parents = commit | { $0.parents() } | { $0.map { $0.oid } }
        return combine(commit,parents)
            | { GitCommitBasicInfo(id: self, commit: $0, parents: $1) }
    }
}

