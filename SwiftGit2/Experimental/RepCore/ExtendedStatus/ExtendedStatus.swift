
import Clibgit2
import Essentials

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
