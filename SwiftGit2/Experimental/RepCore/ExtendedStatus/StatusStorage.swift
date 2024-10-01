
import Foundation
import Essentials



//extension String {
//    var gravatarVM : GravatarViewModel { gravatarVMs.access { $0.item(key: self) { GravatarViewModel(email: $0) } } }
//}


public class StatusStorage {
    var uuid: UUID { status.uuid }
    
    public let repoID: RepoID
    public let status: ExtendedStatus
    public let entries : [StatusEntryID]
    public let hunks = LockedVar<[StatusEntryID:[Diff.Hunk]]>([:])
    
    init(status: ExtendedStatus, repoID: RepoID) {
        self.repoID = repoID
        self.status = status
        self.entries = status.entries(in: repoID)
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
