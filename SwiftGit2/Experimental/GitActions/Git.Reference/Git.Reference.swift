
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
    var HEAD : R<ReferenceID> {
        repoID.repo | { $0.HEAD() } | { ReferenceID(repoID: repoID, name: $0.nameAsReference) }
    }
        
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
