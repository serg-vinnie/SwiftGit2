import Clibgit2
import Foundation
import Essentials

public enum BranchTarget : DuoUser {
    case HEAD
    case branch(Branch)
    case branchShortName(String)
    
    func branch(in repo: Repository) -> R<Branch> {
        switch self {
        case .HEAD: return repo.headBranch()
        case let .branch(branch): return .success(branch)
            
        case let .branchShortName(name):
            return repo.branchLookup(name: "refs/heads/\(name)")
        }
    }
}

public extension Duo where T1 == BranchTarget, T2 == Repository {
    var repo : Repository { value.1 }
    //var target : RemoteTarget { value.0 }
    
    var branchInstance: R<Branch> { value.0.branch(in: value.1) }
    var commit: R<Commit> { branchInstance | { $0.targetOID } | { value.1.commit(oid: $0) } }
    
    var remote : R<Remote> { remoteName | { remoteName in repo.remoteRepo(named: remoteName) } }
    
    var remoteName : R<String> { branchInstance | { repo.remoteName(branch: $0.nameAsReference) } }
}
