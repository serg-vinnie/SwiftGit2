import Foundation
import Essentials
import Clibgit2

internal class Rebase: InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_rebase_free(pointer)
    }
}

internal extension Rebase {
    //
    // https://libgit2.org/libgit2/#HEAD/group/rebase/git_rebase_next
    //
    func next(operation: inout UnsafeMutablePointer<git_rebase_operation>?) -> R<()> {
        git_try("git_rebase_next") {
            git_rebase_next(&operation, self.pointer)
        }
    }
}

internal class RebaseIterator : ResultIterator {
    typealias Success = Void
    
    let rebase : Rebase
    var operation : UnsafeMutablePointer<git_rebase_operation>?
    
    init(rebase: Rebase) { self.rebase = rebase }
    
    func next() -> R<Void?> {   // return nil to complete
        rebase.next(operation: &operation) | { () }
    }
}

extension Rebase {
    
    func iterate() -> R<Void> {
        RebaseIterator(rebase: self).all().asVoid
    }
}
