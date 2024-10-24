import Clibgit2
import Foundation
import Essentials

public extension ReferenceID {
    enum Target {
        case HEAD
        case reference(Reference)
        case branch(Branch)
        case id(ReferenceID)
        case oid(OID)
        
        func reference(in repo: Repository) -> R<Reference> {
            switch self {
            case .HEAD:                 return repo.HEAD()
            case let .reference(ref):   return .success(ref)
            case let .branch(branch):   return repo.reference(name: branch.nameAsReference)
            case .oid(_):               return .wtf("This oid possibly is not a Branch")
            case let .id(id):           return repo.reference(name: id.id)
            }
        }
        
        public func branch(in repo: Repository) -> R<Branch> {
            switch self {
            case .HEAD: return repo.headBranch()
            case let .branch(branch):   return .success(branch)
            case let .reference(ref):   return ref.asBranch()
            case .oid(_):               return .wtf("This oid possibly is not a Branch")
            case let .id(id):           return repo.branchLookup(name: id.id)
            }
        }
        
        public func oid(in repo: Repository) -> R<OID> {
            switch self {
            case .HEAD:                 return repo.headCommit().map{ $0.oid }
            case let .branch(branch):
                let ref = repo.reference(name: branch.nameAsReference)
                return ref | { Duo($0,repo).targetOID() }
            case let .reference(ref):   return ref.with(repo).targetOID()
            case let .oid(oid):         return .success(oid)
            case let .id(id):           return id.targetOID
            }
        }
    }
}


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
            let ref = repo.reference(name: branch.nameAsReference)
            return ref | { Duo($0,repo).targetOID() }

        case let .oid(oid):
            return .success(oid)
        case let .branchShortName(name):
            let ref = repo.reference(name: "refs/heads/\(name)")
            return ref | { Duo($0,repo).targetOID() }
//            return repo.branchLookup(name: )
//                .flatMap{ $0.targetOID }
        }
    }
}

public extension Duo where T1 == BranchTarget, T2 == Repository {
    var repo : Repository { value.1 }
    //var target : RemoteTarget { value.0 }
    
    var branchInstance: R<Branch> { value.0.branch(in: value.1) }
    var commit: R<Commit> {
        self.value.0.oid(in: self.value.1) | { value.1.commit(oid: $0) }
//        branchInstance | { $0.targetOID } | { value.1.commit(oid: $0) }
    }
    
    var remote : R<Remote> { remoteName | { remoteName in repo.remoteRepo(named: remoteName) } }
    
    var remoteName : R<String> { branchInstance | { repo.remoteName(localBr: $0.nameAsReference) } }
    //var remoteName : R<String> { branchInstance | { $0.upstreamName() } | { repo.remoteName(upstream: $0) } }
}
