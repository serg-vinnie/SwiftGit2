import Clibgit2
import Essentials

extension AnyGitObject {
    var oid: OID { OID(git_object_id(pointer).pointee) }
    var type: git_object_t { git_object_type(pointer) }
}

class AnyGitObject : InstanceProtocol {
    let pointer: OpaquePointer
    
    required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit { git_object_free(self.pointer) }
}

extension Repository {
    internal func anyObject(oid: OID) -> R<AnyGitObject> {
        var oid = oid.oid
        
        return git_instance(of: AnyGitObject.self, "git_object_lookup") { p in
            git_object_lookup(&p, self.pointer, &oid, GIT_OBJECT_ANY)
        }
    }
}
