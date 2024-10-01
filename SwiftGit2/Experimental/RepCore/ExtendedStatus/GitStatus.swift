
import Foundation
import Essentials

fileprivate var _storage = LockedVar<[RepoID:StatusStorage]>([:])

struct GitStatus {
    let repoID: RepoID
}

extension GitStatus {
    var current : R<ExtendedStatus> {
        if let storage = _storage[repoID] {
            return .success(storage.status)
        }
        return refreshing()
    }
    
    func refreshing(options: StatusOptions = StatusOptions()) -> R<ExtendedStatus> {
        repoID.repo | { $0.extendedStatus() } | { $0.createStorage(repoID: self.repoID).updatingCache().status }
    }
    
    func refreshingPartial(statusEx newStatus: ExtendedStatus) -> R<ExtendedStatus> {
        guard let storage = _storage[repoID] else { return .wtf("storage not found for \(repoID)") }
        let oldStatusEx = storage.status
        let oldSignature = oldStatusEx.signature
        let newSignature = newStatus.signature
        
        if oldSignature == newSignature {
            let newS = newStatus.replacing(uuid: oldStatusEx.uuid)
            _storage[repoID] = StatusStorage(status: newS, repoID: repoID)
            return .success(newS)
        } else {
            _storage[repoID] = StatusStorage(status: newStatus, repoID: repoID)
            return .success(newStatus)
        }
    }
}

internal extension ExtendedStatus {
    func createStorage(repoID: RepoID) -> StatusStorage {
        StatusStorage(status: self, repoID: repoID)
    }
}

internal extension StatusStorage {
    func updatingCache() -> StatusStorage {
        _storage[repoID] = self
        return self
    }
}

//internal extension GitStatus {
//    var storage : StatusStorage {
//        _storage.access { $0.item(key: self) { GravatarViewModel(email: $0) } }
//    }
//}
