
import Foundation
import Essentials

public class StatusStorage {
    public let repoID: RepoID
    public let hunks = LockedVar<[StatusEntryID:[Diff.Hunk]]>([:])
    
    var statusEx : ExtendedStatus? { _statusEx.read }
    var _statusEx                   = LockedVar<ExtendedStatus?>(nil)
    public let statusListDidChange  = Flow.Signal<Void>(queue: .main)
    
    init(repoID: RepoID) {
        self.repoID = repoID
    }
    
    func refreshing() -> R<ExtendedStatus>  {
        repoID.statusEx()
            .onSuccess { newStatus in
                _statusEx.access { $0 = newStatus }
                self.statusListDidChange.update(())
            }
    }
    
    func refreshingSoft() -> R<ExtendedStatus>  {
        repoID.statusEx() | { self.refreshingSoft(statusEx: $0) }
    }
    
    func refreshingSoft(statusEx newStatus: ExtendedStatus) -> ExtendedStatus {
        guard let oldStatusEx = self._statusEx.read else {
            _statusEx.access { $0 = newStatus }
            self.statusListDidChange.update(())
            return newStatus
        }
        let oldSignature = oldStatusEx.signature
        let newSignature = newStatus.signature
        
        if oldSignature == newSignature {
            self._statusEx.access { $0 = newStatus.replacing(uuid: oldStatusEx.uuid) }
            // NOT HERE
            // self.statusListDidChange.update(())
            //
        } else {
            self._statusEx.access { $0 = newStatus }
            self.statusListDidChange.update(())
        }
        return newStatus
    }
}

extension ExtendedStatus {
    func entries(in repoID: RepoID) -> [StatusEntryID] {
        var list = [StatusEntryID]()
        for i in 0..<status.count {
            list.append(entryID(entry: status[i], repoID: repoID, idx: i))
        }
        return list
    }
    
    func entryID(entry: StatusEntry, repoID: RepoID, idx: Int) -> StatusEntryID {
        StatusEntryID(repoID: repoID, statusID: uuid, idx: idx, stagePath: entry.stagePath)
    }

}
