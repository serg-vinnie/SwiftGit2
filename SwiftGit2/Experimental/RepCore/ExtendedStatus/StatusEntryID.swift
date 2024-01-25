
import Foundation

public struct StatusEntryID : Identifiable, Hashable {
    public let repoID     : RepoID
    public let statusID   : UUID
    public let stagePath: String
    
    public var id: String { repoID.path + "/" + stagePath + "_" + statusID.uuidString }
    
    public init(repoID: RepoID, statusID: UUID, stagePath: String) {
        self.repoID = repoID
        self.statusID = statusID
        self.stagePath = stagePath
    }
}
