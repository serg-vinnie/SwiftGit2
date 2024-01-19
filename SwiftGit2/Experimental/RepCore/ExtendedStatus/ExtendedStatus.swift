
import Clibgit2
import Essentials

public struct StatusEntryID : Identifiable {
    public let repoID : RepoID
    public let idx : Int
    
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
    public let hunks: [Int:StatusEntryHunks]
    
    public static var empty : ExtendedStatus { ExtendedStatus(status: StatusIterator(nil), isConflicted: false, head: .isUnborn, hunks: [:]) }
}

public extension ExtendedStatus {
    func appending(hunks: StatusEntryHunks, at idx: Int) -> ExtendedStatus {
        var newHunks = self.hunks
        newHunks[idx] = hunks
        return ExtendedStatus(status: status, isConflicted: isConflicted, head: head, hunks: newHunks)
    }
}
