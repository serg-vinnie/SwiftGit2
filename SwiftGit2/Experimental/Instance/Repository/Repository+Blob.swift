
import Foundation
import Clibgit2
import Essentials

public extension Repository {
    
    func blobCreateFromDisk(path: String) -> R<OID> {
        var oid = git_oid()
        
        return git_try("git_blob_create_from_disk") {
            git_blob_create_from_disk(&oid, self.pointer, path)
        }
        | { _ in OID(oid) }
    }
    
    func blobCreateFromWorkdir(path: String) -> R<OID> {
        var oid = git_oid()
        
        return git_try("git_blob_create_from_workdir") {
            git_blob_create_from_workdir(&oid, self.pointer, path)
        }
        | { _ in OID(oid) }
    }
}
