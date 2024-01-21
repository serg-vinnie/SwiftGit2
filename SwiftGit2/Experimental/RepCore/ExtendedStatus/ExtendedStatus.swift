
import Clibgit2
import Essentials

public struct StatusEntryID : Identifiable, Hashable {
    public let repoID     : RepoID
    public let idx        : Int
    
    public var id: String { repoID.path + "_\(idx)" }
    
    public init(repoID: RepoID, idx: Int) {
        self.repoID = repoID
        self.idx = idx
    }
}


public struct ExtendedStatus {
    public enum HEAD {
        case isUnborn
        case reference(ReferenceID)
        case dettached(CommitID)
    }
    public let status : StatusIterator
    public let isConflicted : Bool
    public let head: HEAD
    public let uuid = UUID()
    
    public static var empty : ExtendedStatus { ExtendedStatus(status: StatusIterator(nil), isConflicted: false, head: .isUnborn) }
}

public extension ExtendedStatus {
    class Cache {
        public var uuid  = LockedVar<UUID>(UUID())
        public var hunks = LockedVar<[Int:StatusEntryHunks]>([:])
        
        public init() {}
        
        public func verify(uuid: UUID) {
            let _uuid = self.uuid.read { $0 }
            if uuid == _uuid {
                return
            }
            self.uuid.access { $0 = uuid }
            self.hunks.access { $0.removeAll() }
        }
    }
}

