import Essentials
import Clibgit2

public enum BranchBase {
    case head
    case commit(Commit)
    case branch(Branch)
}

public struct GitBranches {
    public let repoID : RepoID
    public init(_ repoID : RepoID) { self.repoID = repoID }
    
    public func new(from target: BranchTarget, name: String, checkout: Bool, stashing: Bool = false) -> R<ReferenceID> {
        repoID.repo
            | { $0.createBranch(from: target, name: name, checkout: checkout, stashing: stashing) }
            | { ReferenceID(repoID: repoID, name: $0.nameAsReference) } 
    }
    
    public var HEAD : R<ReferenceID> {
        repoID.repo | { $0.HEAD() } | { ReferenceID(repoID: repoID, name: $0.nameAsReference) }
    }
    
    public func startTracking(ref: String) -> R<()> {
        let remoteNameToTrack = ref.split(separator: "/").dropFirst(2).joined(separator: "/")
        let newBranchName = ref.split(separator: "/").dropFirst(3).joined(separator: "/")
        
        return repoID.repo.flatMap { repo in
            repo.branchLookup(name: ref)
                .flatMap { remoteBranch in
                    repo.createBranch(from: .branch(remoteBranch), name: newBranchName, checkout: false, stashing: false)
                }
                .flatMap { $0.asBranch() }
            // set as HEAD
                .flatMap { repo.checkout(branch: $0, strategy: .Force, stashing: false) }
            // set HEAD branch's upstream to existing remote branch
                .flatMap { repo.HEAD() }
                .flatMap { $0.asBranch() }
                .flatMap { $0.setUpstream(name: remoteNameToTrack) }
                .flatMap { _ in .success(()) }
        }
    }
}

public extension Repository {
    func createBranch(from target: BranchTarget, name: String, checkout: Bool, stashing: Bool = false) -> R<Reference> {
        let repo = self
        
        return target.oid(in: self)
            .flatMap { repo.commit(oid: $0) }
            .flatMap { commit in repo.createBranch(from: commit, name: name, checkout: checkout, stashing: stashing) }
    }
    
    func branchLookup(name: String) -> R<Branch>{
        reference(name: name)
            .flatMap{ $0.asBranch() }
    }
    
    internal func createBranch(from commit: Commit, name: String, checkout: Bool, force: Bool = false, stashing: Bool) -> R<Reference> {
        var pointer: OpaquePointer?
        
        return git_try("git_branch_create") {
            git_branch_create(&pointer, self.pointer, name, commit.pointer, force ? 0 : 1)
        }
        .map { Reference(pointer!) }
        .if ( checkout,
              then: { self.checkout(reference: $0, strategy: .Safe, pathspec: [], stashing: stashing) })
    }
}
