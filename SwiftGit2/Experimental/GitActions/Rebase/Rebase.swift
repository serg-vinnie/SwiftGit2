import Foundation
import Essentials
import Clibgit2

public class Rebase: InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_rebase_free(pointer)
    }
}
