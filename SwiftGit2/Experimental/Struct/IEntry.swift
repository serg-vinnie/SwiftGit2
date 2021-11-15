
import Foundation

public protocol IEntry {
    var pathInWorkDir: String? { get }
    var isStaged : Bool { get }
}

extension StatusEntry: IEntry {
    public var isStaged: Bool { self.stageState == .staged }
    
    public var pathInWorkDir: String? {
        // indexToWorkDir?
        // headToIndex?
        // self.indexToWorkDir?.newFile
        // self.indexToWorkDir?.oldFile
        // self.headToIndex?.newFile
        // self.headToIndex?.newFile
        
        self.indexToWorkDir?.newFile?.path ?? self.headToIndex?.newFile?.path
    }
}


public extension StatusEntry {
    var stageState: StageState {
        if self.headToIndex != nil && self.indexToWorkDir != nil {
            return .mixed
        }
        
        if let _ = self.headToIndex {
            return .staged
        }
        
        if let _ = self.indexToWorkDir {
            return .unstaged
        }
        
        return .unstaged
    }
}

public enum StageState {
    case mixed
    case staged
    case unstaged
}
