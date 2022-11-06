
import Foundation
import Essentials
import Clibgit2

public struct GitReference {
    let repoID: RepoID
    
    public init(_ repoID: RepoID) {
        self.repoID = repoID
    }
}


public extension GitReference {        
    func new(branch: String, from src: Source, checkout: Bool, stashing: Bool = false) -> R<ReferenceID> {
        GitBranches(repoID)
            .new(from: src.asBranchTarget, name: branch, checkout: checkout, stashing: stashing)
    }
    
    func new(tag: String) -> R<ReferenceID> {
        
        return .notImplemented
    }
    
    enum Source {
        case HEAD
        case id(ReferenceID)
        case oid(OID)
        
        var asBranchTarget : BranchTarget {
            switch self {
            case .HEAD: return .HEAD
            case .oid(let oid): return .oid(oid)
            case .id(let id): return .branchShortName(id.displayName)
            }
        }
    }
}

fileprivate struct GitBranches {
    public let repoID : RepoID
    public init(_ repoID : RepoID) { self.repoID = repoID }

    func new(from target: BranchTarget, name: String, checkout: Bool, stashing: Bool = false) -> R<ReferenceID> {
        repoID.repo
            | { $0.createBranch(from: target, name: name, checkout: checkout, stashing: stashing) }
            | { ReferenceID(repoID: repoID, name: $0.nameAsReference) }
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
