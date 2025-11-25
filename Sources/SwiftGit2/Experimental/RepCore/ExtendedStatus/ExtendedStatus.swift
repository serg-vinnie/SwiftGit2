
import Foundation
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
    public let uuid : UUID
    
    init(status: StatusIterator, isConflicted: Bool, head: HEAD, uuid: UUID = UUID()) {
        self.status = status
        self.isConflicted = isConflicted
        self.head = head
        self.uuid = uuid
    }
    
    public static var empty : ExtendedStatus { ExtendedStatus(status: StatusIterator(nil), isConflicted: false, head: .isUnborn) }
}

public extension ExtendedStatus {
    func replacing(uuid: UUID) -> ExtendedStatus {
        ExtendedStatus(status: self.status, isConflicted: self.isConflicted, head: self.head, uuid: uuid)
    }
}
