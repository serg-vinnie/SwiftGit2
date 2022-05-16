import Foundation
import Essentials

public struct GitStash {
    public let repoID: RepoID
    
    func save(signature: Signature, message: String, flags: StashFlags = .defaultt ) -> R<OID>  {
        return repoID.repo
            .flatMap { $0.stashSave(signature: signature, message: message, flags: flags) }
    }
    
    func load(_ stash: Stash) {
//        repoID.repo
//            .flatMap { $0.stashLoad() }
    }
    
    func items() -> R<[Stash]> {
        return repoID.repo
            .flatMap { $0.stashForeach() }
    }
    
    func remove(_ stash: Stash) -> R<()> {
        return repoID.repo
            .flatMap { $0.stashDrop(stash) }
    }
}
