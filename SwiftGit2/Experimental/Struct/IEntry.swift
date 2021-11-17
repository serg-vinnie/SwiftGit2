
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
