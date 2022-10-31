
import Foundation
import Essentials

public struct CommitID {
    public let repoID: RepoID
    public let oid   : OID
    
    //public var commit : R<Commit> { self.repoID.repo | { $0.commit(oid: self.oid) } }
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
    
    public func withCommit<T>(_ block: (Commit)->R<T>) -> R<T> {
        self.repoID.repo | { repo in
            repo.commit(oid: self.oid) | { block($0) }
        }
    }
}
