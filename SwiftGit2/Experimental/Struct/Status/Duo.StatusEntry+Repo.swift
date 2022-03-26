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
        
// 1
//        let sizeIsSmall = indexToWorkDirNewFileURL
//            .map { $0.fileSize2() < 1024 * 500 } // 500 kb +-
//
//        let entryNotExistInIndex = repo.index().map{ $0.entry(relPath: entry.stagePath) == nil }
//
//        let temp = combine(sizeIsSmall, entryNotExistInIndex)
//            .flatMap { sizeIsSmall, entryNotExistInIndex -> R<()> in
//                if sizeIsSmall && entryNotExistInIndex {
//                    return repo.index().flatMap{ $0.addBy(relPath: entry.stagePath) }.map { _ in () }
//                }
//                return .success(())
//            }
        
        var unStagedHunks : R<[Diff.Hunk]>
        
        if let unStaged = entry.unStagedDeltas {
// 1
//            unStagedHunks = temp.flatMap{ repo.hunksFrom(delta: unStaged ) }
            unStagedHunks = repo.hunksFrom(delta: unStaged )
        } else {
            unStagedHunks = .success([])
        }
        
        return combine(stagedHunks, unStagedHunks)
            .map{ StatusEntryHunks(staged: $0, unstaged: $1) }
    }
}

extension URL {
    func fileSize( units: ByteCountFormatter.Units ) -> UInt64 {
        let byteCountFormatter: ByteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = ByteCountFormatter.CountStyle.file
        
        var fileSizeValue: UInt64 = 0
                
        do {
            let fileAttribute: [FileAttributeKey : Any] = try FileManager.default.attributesOfItem(atPath: self.path)
            
            if let fileNumberSize: NSNumber = fileAttribute[FileAttributeKey.size] as? NSNumber {
                fileSizeValue = UInt64(truncating: fileNumberSize)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return fileSizeValue
    }
}

extension URL {
    func fileSize2() -> Int {
        do {
            let resources = try self.resourceValues(forKeys:[.fileSizeKey])
            let fileSize = resources.fileSize!
            return fileSize
        } catch {
            return 0
        }
    }
    
    private func getHumanReadebleSize(bytes: Int) -> String {
        let bcf = ByteCountFormatter()
        //bcf.allowedUnits = [.useMB, .useKB] // optional: restricts the units to MB and KB only
        bcf.countStyle = .file
        bcf.isAdaptive = true
        let string = bcf.string(fromByteCount: Int64(bytes))
        return string
    }
}
