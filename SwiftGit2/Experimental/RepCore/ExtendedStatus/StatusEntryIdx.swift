
import Clibgit2
import Essentials

public struct StatusEntryIdx : Identifiable, Hashable {
    public let repoID     : RepoID
    public let statusID   : UUID
    public let idx        : Int
    public let stagePath  : String
    
    public var id: String { repoID.path + ":" + stagePath + "_\(idx)@" + statusID.uuidString }
    
    public init(repoID: RepoID, statusID: UUID, idx: Int, stagePath: String) {
        self.repoID = repoID
        self.statusID = statusID
        self.idx = idx
        self.stagePath = stagePath
    }
}
