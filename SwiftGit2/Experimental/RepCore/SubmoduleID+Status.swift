import Foundation
import Essentials
import OrderedCollections

public extension SubmoduleID {
    enum Status {
        case added
        case inited
    }
    
    struct Cursor {
        public let list : OrderedDictionary<RepoID, Status>
        public let pending : [SubmoduleID]
        
        public init(repoID: RepoID) {
            self.list = [repoID : .inited]
            self.pending = []
        }
        
        public init(list: OrderedDictionary<RepoID, Status>, pending: [SubmoduleID]) {
            self.list = list
            self.pending = pending
        }
    }
}

fileprivate extension RepoID {
    var allSubmoduleIDs : R<[SubmoduleID]> {
        self.repo | { repo in
            repo.submodules() | { $0.map { SubmoduleID(repoID: self, name: $0.name) } }
        }
    }
}

extension SubmoduleID.Cursor : ResultIterator {
    public func next() -> R<Self?> {
        guard list.count > 0 else { return .wtf("SubmoduleID.Cursor.list.count == 0")}
        if list.count == 1 && pending == [] {
            let repoID = list.keys[0]
            return repoID.allSubmoduleIDs  | { .init(list: self.list, pending: $0) }
        }
        
        if pending.isEmpty {
            return .success(nil)
        }
        
        var copy = list
        var _pending = [SubmoduleID]()
        
        pending.forEach { id in
            copy[id.subRepoID] = id.status
            
            id.subRepoID.allSubmoduleIDs
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
