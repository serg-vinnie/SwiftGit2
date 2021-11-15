
import Foundation

public protocol IEntry {
    var pathInWorkDir: String? { get }
    var isStaged : Bool { get }
}

extension StatusEntry: IEntry {
    public var isStaged: Bool { false }
    
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
