import Foundation
import Clibgit2
import Essentials

public struct GitCommitBasicInfo {
    let id : CommitID
    let author : GitSignature
    let commiter : GitSignature
    let tree : OID
    let parents : [OID]
    
    let summary     : String
    let description : String
    
    init(id: CommitID, commit: Commit, tree: OID, parents: [OID]) {
        self.id             = id
        self.author         = GitSignature(commit.author)
        self.commiter       = GitSignature(commit.commiter)
        self.tree           = tree
        self.parents        = parents
        self.summary        = commit.summary
        self.description    = commit.description
    }
}

public extension CommitID {
    var basicInfo : R<GitCommitBasicInfo> {
        let treeOID = commit | { $0.tree() } | { $0.oid }
        let parents = commit | { $0.parents() } | { $0.map { $0.oid } }
        return combine(commit,treeOID,parents)
            | { GitCommitBasicInfo(id: self, commit: $0, tree: $1, parents: $2) }
    }
}

