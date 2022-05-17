import Foundation
import Essentials

public struct GitStash {
    public let repoID: RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
    
    public func save(signature: Signature, message: String?, flags: StashFlags = .defaultt ) -> R<OID>  {
        return repoID.repo
            .flatMap { $0.stashSave(signature: signature, message: message, flags: flags) }
    }
    
    public func apply(_ stash: Stash) -> R<()> {
        repoID.repo
            .flatMap { $0.stashApply(stash) }
    }
    
    public func items() -> R<[Stash]> {
        return repoID.repo
            .flatMap { $0.stashForeach() }
    }
    
    public func remove(_ stash: Stash) -> R<()> {
        return repoID.repo
            .flatMap { $0.stashDrop(stash) }
    }
}
