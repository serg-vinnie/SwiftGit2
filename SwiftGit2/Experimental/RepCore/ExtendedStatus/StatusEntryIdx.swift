
import Clibgit2
import Essentials

public struct StatusEntryIdx : Identifiable, Hashable {
    public let repoID     : RepoID
    public let statusID   : UUID
    public let idx        : Int
    
    public var id: String { repoID.path + statusID.uuidString + "_\(idx)" }
    
    public init(repoID: RepoID, statusID: UUID, idx: Int) {
        self.repoID = repoID
        self.statusID = statusID
        self.idx = idx
    }
}
