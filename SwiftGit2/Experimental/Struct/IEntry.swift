
import Foundation
import Essentials

public protocol IEntry {
    var stagePath: String { get }
    
    var stageState: StageState { get }
    var entryFileInfo: R<EntryFileInfo> { get }
    
    var statuses: [Diff.Delta.Status] { get }
    
    var id: String { get }
}

extension StatusEntry: IEntry {
    public var id: String { "\(stagePath)_____\(statuses)" }
    
    public var stagePath: String {
        let res = self.indexToWorkDir?.newFile?.path ?? self.headToIndex?.newFile?.path ?? ""
        
        assert(res != "")
        
        return res
    }
    
    public var stageState: StageState {
        if self.headToIndex != nil && self.indexToWorkDir != nil {
            return .mixed
        }
        
        if let _ = self.headToIndex {
            return .staged
        }
        
        if let _ = self.indexToWorkDir {
            return .unstaged
        }
        
        return .unavailable
    }
    
    public var entryFileInfo: R<EntryFileInfo> {
        let staged = self.headToIndex
        let unStaged = self.indexToWorkDir
        
        let oldPath = staged?.oldFile?.path ?? unStaged?.oldFile?.path
        let newPath = staged?.newFile?.path ?? unStaged?.newFile?.path
        
        if let oldPath = oldPath,
           let newPath = newPath,
           oldPath != newPath {
            return .success(.renamed(oldPath, newPath))
        } else if let newPath = newPath {
            return .success(.single(newPath))
        } else if let oldPath = oldPath {
            return .success(.single(oldPath))
        }
        
        return .failure(WTF("EntryFileInfo error"))
    }
    
    public var statuses: [Diff.Delta.Status] {
        if let status = unStagedDeltas?.status,
           stagedDeltas == nil {
                return [status]
        }
        if let status = stagedDeltas?.status,
            unStagedDeltas == nil {
                return [status]
        }
        
        guard let workDir = unStagedDeltas?.status else { return [.unmodified] }
        guard let index = stagedDeltas?.status else { return [.unmodified] }
        
        if workDir == index {
            return [workDir]
        }
        
        return [workDir, index]
    }
}

extension Diff.Delta: IEntry {
    public var stagePath: String {
        guard let path = self.newFile?.path else {
            assert(false)
            return ""
        }
        
        return path
    }
    
    public var statuses: [Diff.Delta.Status] {
        [self.status]
    }
    
    public var stageState: StageState { .unavailable}
    
    public var entryFileInfo: R<EntryFileInfo> {
        guard stagePath != "" else { return .failure(WTF("stagePath is NIL")) }
        
        if stagePath != self.oldFile?.path {
            if let oldFile = self.oldFile?.path {
                return .success(.renamed(oldFile, stagePath))
            }
        }
        
        return .success(.single(stagePath))
    }
}

public extension IEntry {
    func getFileType() -> FileType {
        if stagePath.lowercased().hasSuffix( [// Absolutely sure supported extensions
            ".jpeg",".jpg", ".gif", ".ai", ".pdf", ".eps",".icns",".jp2",".ico",".pbm",".pgm",
            ".pict",".png",".ppm",".psd",".sgi",".tga",".tiff",".cr2",".dng",".heic", ".heif",
            ".nef",".nrw",".orf",".pef",".raf",".rw2",".webp",".bmp",".dds",".exr",".hdr",".jpe",
            ".pgm"
            //not tested
            //".j2k", ".jpf", ".jpm", ".jpg2", ".j2c", ".jpc", ".jpx", ".mj2",
            //".pct", ".pic",".pnm",".qtif",".stl",".icb", ".vda",".tif"
        ] ) {
            return .Img
        }
        
        //TODO: TEXT FILE
        
        return .SomeBinary
    }
}

public enum FileType {
    case Img
    case SomeBinary
}

public enum StageState {
    case mixed
    case staged
    case unstaged
    case unavailable
}

public enum EntryFileInfo {
    case single(String)
    case renamed(String, String)
}
