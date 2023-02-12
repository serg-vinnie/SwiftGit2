
import Clibgit2
import Essentials

public struct StatusEntryID {
    public let repoID : RepoID
    public let idx : Int
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
    public let head: HEAD
    public let hunks: [Int:StatusEntryHunks]
}

public extension ExtendedStatus {
    func appending(hunks: StatusEntryHunks, at idx: Int) -> ExtendedStatus {
        var newHunks = self.hunks
        newHunks[idx] = hunks
        return ExtendedStatus(status: status, head: head, hunks: newHunks)
    }
}
