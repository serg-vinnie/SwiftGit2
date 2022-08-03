import Clibgit2
import Foundation
import Essentials

public enum BranchTarget : DuoUser {
    case HEAD
    case branch(Branch)
    case branchShortName(String)
    case oid(OID)
    
    public func branch(in repo: Repository) -> R<Branch> {
        switch self {
        case .HEAD: return repo.headBranch()
        case let .branch(branch): return .success(branch)
        case .oid(_): return .wtf("This oid possibly is not a Branch")
        case let .branchShortName(name): return repo.branchLookup(name: "refs/heads/\(name)")
        }
    }
    
    public func oid(in repo: Repository) -> R<OID> {
        switch self {
        case .HEAD:
            return repo.headCommit().map{ $0.oid }
        case let .branch(branch):
            return branch
                .targetOID
        case let .oid(oid):
            return .success(oid)
        case let .branchShortName(name):
            return repo.branchLookup(name: "refs/heads/\(name)")
                .flatMap{ $0.targetOID }
        }
    }
}

public extension Duo where T1 == BranchTarget, T2 == Repository {
    var repo : Repository { value.1 }
    //var target : RemoteTarget { value.0 }
    
    var branchInstance: R<Branch> { value.0.branch(in: value.1) }
    var commit: R<Commit> { branchInstance | { $0.targetOID } | { value.1.commit(oid: $0) } }
    
    var remote : R<Remote> { remoteName | { remoteName in repo.remoteRepo(named: remoteName) } }
    
    var remoteName : R<String> { branchInstance | { repo.remoteName(localBr: $0.nameAsReference) } }
    //var remoteName : R<String> { branchInstance | { $0.upstreamName() } | { repo.remoteName(upstream: $0) } }
}
