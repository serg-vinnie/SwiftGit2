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
    
    func commit(signature: Signature) -> R<OID> {
        var oid = git_oid()
        return signature.make() | { signature in
            git_try("git_rebase_commit") {
                git_rebase_commit(&oid, self.pointer,
                                  nil /* author */,
                                  signature.pointer /*committer*/,
                                  nil /* message_encoding */,
                                  nil /* message */)
            }
        } | { OID(oid) }
    }
}



