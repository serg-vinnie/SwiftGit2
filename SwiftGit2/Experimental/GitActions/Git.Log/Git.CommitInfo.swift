import Foundation
import Clibgit2
import Essentials

public struct GitCommitInfo {
    let id : CommitID
    let deltas : CommitDeltas
}

extension CommitID {
    
    var basicInfo : R<GitCommitBasicInfo> {
        let treeOID = commit | { $0.tree() } | { $0.oid }
        let parents = commit | { $0.parents() } | { $0.map { $0.oid } }
        return combine(commit,treeOID,parents)
            | { GitCommitBasicInfo(id: self, commit: $0, tree: $1, parents: $2) }
    }
}

public struct GitCommitBasicInfo {
    let id : CommitID
    let author : GitSignature
    let commiter : GitSignature
    let tree : OID
    
    init(id: CommitID, commit: Commit, tree: OID, parents: [OID]) {
        self.id         = id
        self.author     = GitSignature(commit.author)
        self.commiter   = GitSignature(commit.commiter)
        self.tree       = tree
    }
}

public struct GitSignature {
    let name    : String
    let email   : String
    let when    : Date
    
    init(_ signature: git_signature) {
        self.name = signature.name.asString()
        self.email = signature.email.asString()
        self.when  = signature.when.time.asDate()
    }
    
    init(name: String, email: String, when: Date) {
        self.name = name
        self.email = email
        self.when = when
    }
}


fileprivate extension git_time_t {
    func asDate() -> Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}

//
//fileprivate extension Int64 {
//    func asDate() -> Date {
//        Date(timeIntervalSince1970: TimeInterval(self))
//    }
//}
