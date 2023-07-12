
import Foundation
import Essentials

public struct CommitID : CustomStringConvertible, Hashable, Identifiable {
    public var id: OID { oid }  // Identifiable
    
    public let repoID: RepoID
    public let oid   : OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }

    public var commit: R<Commit> { self.repoID.repo | { repo in repo.commit(oid: self.oid) } }
    public var deltas: R<CommitDeltas> { self.repoID.repo | { repo in repo.deltas(target: .commit(oid)) } }
    
    public func withCommit<T>(_ block: (Commit)->R<T>) -> R<T> {
        self.repoID.repo | { repo in
            repo.commit(oid: self.oid) | { block($0) }
        }
    }
    
    public var description: String { "\(repoID):\(oid)" }
}

public extension CommitID {
    func checkout(strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil, pathspec: [String] = [], stashing: Bool) -> R<DetachedHeadFix> {
        repoID.repo
        | { $0.checkout(oid, strategy: strategy, progress: progress, pathspec: pathspec, stashing: stashing) }
        | { $0.detachedHeadFix() }
    }
    
    func checkout(options: CheckoutOptions, fixDetachedHead: Bool, stashing: Bool) -> R<Void> {
        if fixDetachedHead {
            return repoID.repo | { repo in
                repo.checkout(oid, options: options, stashing: stashing) | { _ in repo.detachedHeadFix().asVoid }
            }
        } else {
            return repoID.repo | { $0.checkout(oid, options: options, stashing: stashing) }
        }
    }
}

extension Repository {
    internal func checkout(_ oid: OID, options: CheckoutOptions, stashing: Bool) -> R<Void> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            checkout(oid, options: options)
        }
    }
    internal func checkout(_ oid: OID, options: CheckoutOptions) -> R<Void> {
        setHEAD_detached(oid) | { checkoutHead(options: options) }
    }
}
