
import Foundation
import Clibgit2
import Essentials

public extension ReferenceID {
    func rename( _ newName: String, force: Bool = false) -> R<ReferenceID> {
        let reflog = "branch: renamed " + self.id + " to " + self.prefix + newName
        
        let repo = self.repoID.repo
        let reference = repo | { $0.reference(name: self.id) }
        let upstream = self.upstream.maybeSuccess
        
        return reference
                | { $0.rename(self.prefix + newName, reflog: reflog, force: force) }
                | { ReferenceID(repoID: self.repoID, name: $0.nameAsReference) }
                | { $0.setting(upstream: upstream) }
    }
    
    private func setting(upstream: ReferenceID?) -> R<ReferenceID> {
        if let upstream = upstream {
            return self.set(upstream: upstream) | { _ in self }
        }
        return .success(self)
    }
}

public extension ReferenceID {
    func createUpstreamAt(remote: String, reflog: String = "update by push", force: Bool = false) -> R<ReferenceID> {
        guard isBranch else { return .wtf("can't create upstream: not a branch")  }
        let upstreamID = ReferenceID(repoID: repoID, name: id.replace(of: "refs/heads", to: "refs/remotes/\(remote)"))
        
        return targetOID | { upstreamID.create(at: $0, reflog: reflog, force: force) }
                         | { self.set(upstream: $0) }
    }
    
    var upstream : R<ReferenceID> {
        let repo = self.repoID.repo
        return repo | { $0.reference(name: self.id) }
                    | { $0.upstream() }
                    | { ReferenceID(repoID: self.repoID, name: $0.nameAsReference) }
    }
    
    func set(upstream: ReferenceID) -> R<ReferenceID> {
        guard upstream.isRemote else { return .wtf("can't set upstream: not a remote branch : \(upstream.id)") }
        let repo = self.repoID.repo
        let reference = repo | { $0.reference(name: self.id) }
        
        return reference | { $0.setUpstream(name: upstream.displayNameEx) } | { _ in upstream }
    }
    
    func create(at oid: OID, reflog: String, force: Bool) -> R<ReferenceID> {
        repoID.repo | { $0.createReference(name: self.id, oid: oid, force: force, reflog: reflog) }
                    | { _ in self }
    }
}

extension Repository {
    func createReference(name: String, oid: OID, force: Bool, reflog: String)-> R<Reference> {
        var oid = oid.oid
        
        return git_instance(of: Reference.self, "git_reference_create") { pointer in
            git_reference_create(&pointer, self.pointer, name, &oid, force ? 1 : 0, reflog)
        }
    }
}

//private extension Repository {
//    func __createUpstream(for branch: Branch, force: Bool) -> R<Branch> {
//        let oid = branch.targetOID
//        let referenceName = remoteInstance | { $0.name.asNonOptional("remote.name == nil") }
//                                           | { branch.nameAsReference.replace(of: "heads", to: "remotes/\($0)") }
//        let upstreamName  = referenceName  | { $0.replace(of: "refs/remotes/", to: "") }
//
//        return combine(referenceName, oid)
//            | { repo.createReference(name: $0, oid: $1, force: force, reflog: "TaoSync: upstream for \(branch.nameAsReference)") }
//            | { _ in upstreamName }
//            | { branch.setUpstream(name: $0)}
//    }
//}
//}


extension Reference {
    func rename( _ newName: String, reflog: String, force: Bool) -> R<Reference> {
        return git_instance(of: Reference.self, "git_reference_rename") { pointer in
            git_reference_rename(&pointer, self.pointer, newName, force ? 1 : 0, reflog)
        }
    }
    
    /// newName like  "origin/BrowserGridItemView"
    /// BUT NOT LIKE "refs/heads/BrowserGridItemView"
    func setUpstream(name: String) -> R<Branch> {
        git_try("git_branch_set_upstream") {
            git_branch_set_upstream(self.pointer, name)
        }.map { self }
    }
}

public extension Branch {
    
    /// newName like  "origin/BrowserGridItemView"
    /// BUT NOT LIKE "refs/heads/BrowserGridItemView"
    func _setUpstream(name: String) -> R<Branch> {
        git_try("git_branch_set_upstream") {
            git_branch_set_upstream(self.pointer, name)
        }.map { self }
    }
}
