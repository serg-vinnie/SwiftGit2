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
    
    func hunks(options: DiffOptions) -> R<StatusEntryHunks> {
        let (entry, repo) = self.value
        if entry.statuses.contains(.untracked) {
            return repo.hunksFrom(relPath: entry.stagePath, options: options)
                .map { StatusEntryHunks(staged: .empty, unstaged: $0) }
        }
        
        let stagedHunks : R<HunksResult>
        
        if let staged = entry.stagedDeltas {
            stagedHunks = repo.hunksFrom(delta: staged, options: options )
        } else {
            stagedHunks = .success(.empty)
        }
        
        
        var unStagedHunks : R<HunksResult>
        
        if let unStaged = entry.unStagedDeltas {
// 1
//            unStagedHunks = temp.flatMap{ repo.hunksFrom(delta: unStaged ) }
            unStagedHunks = repo.hunksFrom(delta: unStaged, options: options )
        } else {
            unStagedHunks = .success(.empty)
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
