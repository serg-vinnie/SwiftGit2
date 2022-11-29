
import Foundation
import Essentials

public struct CommitID : CustomStringConvertible, Hashable {
    public let repoID: RepoID
    public let oid   : OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }

    public var commit: R<Commit> { self.repoID.repo | { repo in repo.commit(oid: self.oid) } }
    
    public func withCommit<T>(_ block: (Commit)->R<T>) -> R<T> {
        self.repoID.repo | { repo in
            repo.commit(oid: self.oid) | { block($0) }
        }
    }
    
    public var description: String { "\(repoID):\(oid)" }
}

public extension CommitID {
    func checkout(_ oid: OID, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil, pathspec: [String] = [], stashing: Bool) -> R<DetachedHeadFix> {
        repoID.repo
        | { $0.checkout(oid, strategy: strategy, progress: progress, pathspec: pathspec, stashing: stashing) }
        | { $0.detachedHeadFix() }
    }
}
