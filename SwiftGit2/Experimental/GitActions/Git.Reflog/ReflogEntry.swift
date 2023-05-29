
import Foundation
import Clibgit2
import Essentials

class ReflogEntry : InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
}

extension ReflogEntry {
    var oldOID : OID { OID(git_reflog_entry_id_old(self.pointer).pointee) }
    var newOID : OID { OID(git_reflog_entry_id_new(self.pointer).pointee) }
    
    var commiter : GitSignature { GitSignature(git_reflog_entry_committer(self.pointer).pointee) }
    var message  : String { String(validatingUTF8: git_reflog_entry_message(self.pointer)) ?? "" }
}
