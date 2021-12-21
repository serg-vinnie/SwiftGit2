
import Clibgit2
import Essentials

public struct StatusEntry {
    public let status: Status
    public let headToIndex: Diff.Delta?
    public let indexToWorkDir: Diff.Delta?

    public init(from statusEntry: git_status_entry) {
        status = Status(rawValue: statusEntry.status.rawValue)

        if let htoi = statusEntry.head_to_index {
            headToIndex = Diff.Delta(htoi.pointee)
        } else {
            headToIndex = nil
        }

        if let itow = statusEntry.index_to_workdir {
            indexToWorkDir = Diff.Delta(itow.pointee)
        } else {
            indexToWorkDir = nil
        }
    }
}

public extension StatusEntry {
    var headToIndexNEWFilePath : R<String> {
        self.headToIndex.asNonOptional("headToIndex_newFilePath") | { $0.newFilePath }
    }
    
    var headToIndexOLDFilePath : R<String> {
        self.headToIndex.asNonOptional("headToIndex_oldFilePath") | { $0.oldFilePath }
    }
    
    var indexToWorkDirNEWFilePath : R<String> {
        self.indexToWorkDir.asNonOptional("indexToWorkDir_newFilePath") | { $0.newFilePath }
    }
    
    var indexToWorkDirOLDFilePath : R<String> {
        self.indexToWorkDir.asNonOptional("indexToWorkDir_oldFilePath") | { $0.oldFilePath }
    }
}

public extension StatusEntry {
    func hunks(repo: Repository) -> R<StatusEntryHunks> {
        if self.statuses.contains(.untracked) {
            return repo.hunkFrom(relPath: self.stagePath)
                .map { StatusEntryHunks(staged: [], unstaged: [$0]) }
        }
        
        let stagedHunks : R<[Diff.Hunk]>
        
        if let staged = self.stagedDeltas {
            stagedHunks = repo.hunksFrom(delta: staged )
        } else {
            stagedHunks = .success([])
        }
        
        let unStagedHunks : R<[Diff.Hunk]>
        
        if let unStaged = self.unStagedDeltas {
            unStagedHunks = repo.hunksFrom(delta: unStaged )
        } else {
            unStagedHunks = .success([])
        }
        
        return combine(stagedHunks, unStagedHunks)
            .map{ StatusEntryHunks(staged: $0, unstaged: $1) }
    }
}



public extension Diff.Delta {
    var newFilePath : R<String> {
        self.newFile.asNonOptional("newFile") | { $0.path }
    }
    
    var oldFilePath : R<String> {
        self.oldFile.asNonOptional("oldFile") | { $0.path }
    }
}
