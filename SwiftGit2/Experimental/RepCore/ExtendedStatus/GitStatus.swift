
import Foundation
import Essentials

fileprivate var _storage = LockedVar<[RepoID:StatusStorage]>([:])

public struct GitStatus {
    let repoID: RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitStatus {
    private var storage : StatusStorage {
        _storage.item(key: repoID) { StatusStorage(repoID: $0) }
    }
    
    var statusListDidChange : S<Void> { storage.statusListDidChange }
    
    func refreshing() -> R<ExtendedStatus> {
        storage.refreshing()
    }
    
    func refreshingSoft() -> R<ExtendedStatus> {
        storage.refreshingSoft()
    }
    
//    var statusEx : R<ExtendedStatus> {
//        storage | { $0.statusEx }
//    }
}
