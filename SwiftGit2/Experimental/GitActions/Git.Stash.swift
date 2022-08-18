import Foundation
import Essentials

public struct GitStash {
    public let repoID: RepoID
    public init(repoID: RepoID) { self.repoID = repoID }
}

public extension GitStash {
    func save(signature: Signature, message: String?, flags: StashFlags = .defaultt ) -> R<OID>  {
        return repoID.repo
            .flatMap { $0.stashSave(signature: signature, message: message, flags: flags) }
    }
    
    func apply(stashIdx: Int) -> R<()> {
        repoID.repo
            .flatMap { $0.stashApply(stashIdx:stashIdx) }
    }
    
    func items() -> R<[Stash]> {
        return repoID.repo
            .flatMap { $0.stashForeach() }
    }
    
    func remove(stashIdx: Int) -> R<()> {
        return repoID.repo
            .flatMap { $0.stashDrop(stashIdx: stashIdx) }
    }
}
