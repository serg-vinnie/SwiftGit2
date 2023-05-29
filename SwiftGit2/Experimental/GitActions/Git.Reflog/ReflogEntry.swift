
import Foundation
import Clibgit2
import Essentials

public class ReflogEntry {
    public var pointer: OpaquePointer
    let reflog: Reflog
    
    init(_ pointer: OpaquePointer, reflog: Reflog) {
        self.pointer = pointer
        self.reflog = reflog
    }
}

extension ReflogEntry {
    var oldOID : OID { OID(git_reflog_entry_id_old(self.pointer).pointee) }
    var newOID : OID { OID(git_reflog_entry_id_new(self.pointer).pointee) }
    
    var commiter : GitSignature { GitSignature(git_reflog_entry_committer(self.pointer).pointee) }
    var message  : String { String(validatingUTF8: git_reflog_entry_message(self.pointer)) ?? "" }
}


extension ReflogEntry : CustomStringConvertible {
    public var description: String {
        let old = oldOID.oidShort
        let new = newOID.oidShort
        let author = commiter.email
        let msg = self.message
        
        return "\(old) -> \(new) : \(author) [\(msg)]"
    }
}
