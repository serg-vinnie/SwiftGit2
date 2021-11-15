
import Foundation

public protocol IEntry {
    var pathInWorkDir: String? { get }
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
}
