
import Foundation

struct StatuEntryID : Identifiable, Hashable {
    public let repoID     : RepoID
    public let statusID   : UUID
    public let stagingPath: String
    
    public var id: String { repoID.path + "/" + stagingPath + "_" + statusID.uuidString }
}
