
import Foundation
import Essentials

public protocol IEntry {
    // unique id for navigation
    // stagePath  pathInWorkDir
    var stagePath: String? { get }
    
    
    var stageState: StageState { get }
    var entryFileInfo: R<EntryFileInfo> { get }
    
    var statuses: [Diff.Delta.Status] { get }
}

extension StatusEntry: IEntry {
    public var stagePath: String? {
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
    public var stagePath: String? { self.newFile?.path }
    
    public var statuses: [Diff.Delta.Status] {
        [self.status]
    }
    
    public var stageState: StageState { .unavailable}
    
    public var entryFileInfo: R<EntryFileInfo> {
        guard let stagePath = stagePath else { return .failure(WTF("pathInWorkDir is NIL")) }
        
        if stagePath != self.oldFile?.path {
            if let oldFile = self.oldFile?.path {
                return .success(.renamed(oldFile, stagePath))
            }
        }
        
        return .success(.single(stagePath))
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
