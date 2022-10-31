import Foundation
import Clibgit2

public struct GitCommitInfo {
    let id : CommitID
    let deltas : CommitDeltas
}

public struct GitCommitBasicInfo {
    let id : CommitID
    let author : GitSignature
    let commiter : GitSignature
    
    init(id: CommitID, author: GitSignature, commiter: GitSignature) {
        self.id = id
        self.author = author
        self.commiter = commiter
    }
    
    init(id: CommitID, commit: Commit) {
        self.id         = id
        self.author     = GitSignature(commit.author)
        self.commiter   = GitSignature(commit.commiter)
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
