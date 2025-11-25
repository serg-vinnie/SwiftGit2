
import Foundation
import Clibgit2
import Essentials

class Reflog : InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_reflog_free(pointer)
    }
}


extension Repository {
    func reflog(name: String) -> R<Reflog> {
        git_instance(of: Reflog.self, "git_reflog_read") { pointer in
            git_reflog_read(&pointer, self.pointer, name)
        }
    }
}

extension Reflog {
    var entryCount : Int { git_reflog_entrycount(self.pointer) }
    
    func entry(idx: Int, repoID: RepoID) -> ReflogEntry? {
        guard let entry = git_reflog_entry_byindex(self.pointer, idx) else { return nil }
        return ReflogEntry(entry, reflog: self, idx: idx, repoID: repoID)
    }
    
    func append(signature: Signature, oid: OID, msg: String) -> R<Void> {
        var oid = oid.oid
        return signature.make() | { sig in
            git_try("git_reflog_append") {
                git_reflog_append(self.pointer, &oid, sig.pointer, msg)
            }
        }
        
    }
}
