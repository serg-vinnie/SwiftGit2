
import Foundation
import Clibgit2
import Essentials

public extension ReferenceID {
    func rename( _ newName: String, force: Bool = false) -> R<ReferenceID> {
        let reflog = "branch: renamed " + self.id + " to " + self.prefix + newName
        
        let repo = self.repoID.repo
        let reference = repo | { $0.reference(name: self.id) }
        
        return reference
            | { $0.rename(self.prefix + newName, reflog: reflog, force: force) }
            | { ReferenceID(repoID: self.repoID, name: $0.nameAsReference) }
    }
}



private extension Reference {
    func rename( _ newName: String, reflog: String, force: Bool) -> R<Reference> {
        return git_instance(of: Reference.self, "git_reference_rename") { pointer in
            git_reference_rename(&pointer, self.pointer, newName, force ? 1 : 0, reflog)
        }
    }
}
