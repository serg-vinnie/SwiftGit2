
import Foundation
import Essentials

public protocol IEntry {
    var pathInWorkDir: String? { get }
    var stageState: StageState { get }
    var entryFileInfo: R<EntryFileInfo> { get }
}

extension StatusEntry: IEntry {
    public var pathInWorkDir: String? {
        // indexToWorkDir?
        // headToIndex?
        // self.indexToWorkDir?.newFile
        // self.indexToWorkDir?.oldFile
        // self.headToIndex?.newFile
        // self.headToIndex?.newFile
        
        self.indexToWorkDir?.newFile?.path ?? self.headToIndex?.newFile?.path
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
        
            
        return .failure(WTF(""))
    }
}

extension Diff.Delta: IEntry {
    public var pathInWorkDir: String? { self.newFile?.path }
    
    public var stageState: StageState { .unavailable}
    
    public var entryFileInfo: R<EntryFileInfo> {
        guard let pathInWorkDir = pathInWorkDir else { return .failure(WTF("pathInWorkDir is NIL")) }
        
        if pathInWorkDir != self.oldFile?.path {
            if let oldFile = self.oldFile?.path {
                return .success(.renamed(oldFile, pathInWorkDir))
            }
        }
        
        return .success(.single(pathInWorkDir))
    }
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
