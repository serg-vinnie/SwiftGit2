
import Foundation
import Essentials
import Clibgit2

public struct GitReference {
    let repoID: RepoID
    
    init(_ repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitReference {
    
    enum Target {
        case HEAD
        case id(ReferenceID)
        case oid(OID)
        
        func reference(in repo: Repository) -> R<Reference> {
            switch self {
            case .HEAD:                 return repo.HEAD()
            case .oid(_):               return .wtf("This oid possibly is not a Branch")
            case let .id(id):           return repo.reference(name: id.id)
            }
        }
        
        public func branch(in repo: Repository) -> R<Branch> {
            switch self {
            case .HEAD: return repo.headBranch()
            case .oid(_):               return .wtf("This oid possibly is not a Branch")
            case let .id(id):           return repo.branchLookup(name: id.id)
            }
        }
        
        public func oid(in repo: Repository) -> R<OID> {
            switch self {
            case .HEAD:                 return repo.headCommit().map{ $0.oid }
            case let .oid(oid):         return .success(oid)
            case let .id(id):           return id.targetOID
            }
        }
    }
    
    
    func new(branch: String) -> R<ReferenceID> {
        
        return .notImplemented
    }
    
    func new(tag: String) -> R<ReferenceID> {
        
        return .notImplemented
    }
}
