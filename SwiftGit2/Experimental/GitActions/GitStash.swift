import Foundation
import Essentials

public struct GitStash {
    public let repoID: RepoID
    
    func save() {
        
    }
    
    func load() {
        
    }
    
    func items() -> R<[Stash]> {
        return repoID.repo
            .flatMap { $0.stashForeach() }
    }
    
    func remove() {
        //Drop
    }
}
