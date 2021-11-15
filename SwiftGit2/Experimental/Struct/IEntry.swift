
import Foundation

public protocol IEntry {
    var pathInWorkDir: String? { get }
    var stageState: StageState { get }
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
}

extension Diff.Delta: IEntry {
    public var pathInWorkDir: String? { self.newFile?.path }
    
    public var stageState: StageState { .unavailable}
}

public enum StageState {
    case mixed
    case staged
    case unstaged
    case unavailable
}
