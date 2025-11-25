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
    var operationsCount : Int { git_rebase_operation_entrycount(self.pointer) }
    var currentOperationIdx : Int { git_rebase_operation_current(self.pointer) }
    var currentOperation : UnsafeMutablePointer<git_rebase_operation>? { operation(idx: currentOperationIdx) }
    
    func operation(idx: Int) -> UnsafeMutablePointer<git_rebase_operation>? {
        git_rebase_operation_byindex(self.pointer, idx)
    }
    
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
                                  nil /* message */)  //The message for this commit, or NULL to use the message from the original commit.
            }
        } | { OID(oid) }
    }
    
    func finish(signature: Signature) -> R<Void> {
        signature.make().flatMap { sig in
            git_try("git_rebase_finish") {
                git_rebase_finish(self.pointer, sig.pointer)
            }
        }
    }
}



