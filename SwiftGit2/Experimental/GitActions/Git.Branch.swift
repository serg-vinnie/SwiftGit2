import Essentials
import Clibgit2

public enum BranchBase {
    case head
    case commit(Commit)
    case branch(Branch)
}

public struct GitBranches {
    public let repoID : RepoID
    public init(repoID : RepoID) { self.repoID = repoID }
    
    func createBranch(from target: BranchTarget, name: String, checkout: Bool) -> R<Reference> {
        repoID.repo | { $0.createBranch(from: target, name: name, checkout: checkout) }       
    }

}

public extension Repository {
    func createBranch(from target: BranchTarget, name: String, checkout: Bool) -> R<Reference> {
        let repo = self
        
        return target.oid(in: self)
            .flatMap { repo.commit(oid: $0) }
            .flatMap { commit in repo.createBranch(from: commit, name: name, checkout: checkout) }
    }
    
    func branchLookup(name: String) -> R<Branch>{
        reference(name: name)
            .flatMap{ $0.asBranch() }
    }
    
    internal func createBranch(from commit: Commit, name: String, checkout: Bool, force: Bool = false) -> R<Reference> {
        var pointer: OpaquePointer?
        
        return git_try("git_branch_create") {
            git_branch_create(&pointer, self.pointer, name, commit.pointer, force ? 0 : 1)
        }
        .map { Reference(pointer!) }
        .if ( checkout,
              then: { self.checkout(reference: $0, strategy: .Safe, pathspec: []) })
    }
}
