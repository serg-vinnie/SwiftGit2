import Foundation
import Clibgit2
import Essentials

public extension Duo where T1 == StatusEntry, T2 == Repository {
    var headToIndexNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.headToIndexNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
    
    var indexToWorkDirNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.indexToWorkDirNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
    
    var hunks : R<StatusEntryHunks> {
        let (entry, repo) = self.value
        if entry.statuses.contains(.untracked) {
            return repo.hunkFrom(relPath: entry.stagePath)
                .map { StatusEntryHunks(staged: [], unstaged: [$0]) }
        }
        
        let stagedHunks : R<[Diff.Hunk]>
        
        if let staged = entry.stagedDeltas {
            stagedHunks = repo.hunksFrom(delta: staged )
        } else {
            stagedHunks = .success([])
        }
        
        let unStagedHunks : R<[Diff.Hunk]>
        
        
//        var virtualIndex = Index.new()
//
//        virtualIndex = virtualIndex.flatMap{ $0.addBy(relPath: entry.stagePath, inMemory: true) }
//
//        unStagedHunks = virtualIndex
//            .flatMap { index in
//                repo.diffIndexToWorkdir(index: index)
//            }
//            .flatMap{ $0.asDeltasWithHunks() }
//            .map { $0.first!.hunks }
//            .onFailure{ print("ZZZ \($0)" ) }
        
        if let unStaged = entry.unStagedDeltas {
            unStagedHunks = repo.hunksFrom(delta: unStaged )
        } else {
            unStagedHunks = .success([])
        }
        
        return combine(stagedHunks, unStagedHunks)
            .map{ StatusEntryHunks(staged: $0, unstaged: $1) }
    }
}
