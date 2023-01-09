import Foundation
import Essentials
import OrderedCollections

public extension SubmoduleID {
    enum Status {
        case added
        case inited
    }
    
    struct Cursor {
        let list : OrderedDictionary<RepoID, Status>
        let pending : [SubmoduleID]
        
        init(repoID: RepoID) {
            self.list = [repoID : .inited]
            self.pending = []
        }
        
        init(list: OrderedDictionary<RepoID, Status>, pending: [SubmoduleID]) {
            self.list = list
            self.pending = pending
        }
    }
}

extension SubmoduleID.Cursor : ResultIterator {
    public func next() -> R<Self?> {
        guard list.count > 0 else { return .wtf("SubmoduleID.Cursor.list.count == 0")}
        if list.count == 1 && pending == [] {
            let repoID = list.keys[0]
            return repoID.module | { $0.submoduleIDs } | { .init(list: self.list, pending: $0) }
        }
        
        if pending.isEmpty {
            return .success(nil)
        }
        
        var copy = list
        var _pending = [SubmoduleID]()
        
        pending.forEach { id in
            copy[id.subRepoID] = id.status
            
            (id.subRepoID.module | { $0.submoduleIDs })
                .onSuccess {
                    _pending.append(contentsOf: $0)
                }
        }
        
        return .success(.init(list: copy, pending: _pending))
    }
}

internal extension SubmoduleID {
    var status : Status { repoID.exists ? .inited : .added }
}

extension RepoID {
    func submoduleStatus() -> R<OrderedDictionary<SubmoduleID, SubmoduleID.Status>> {
        
        
        return .notImplemented
    }
}
