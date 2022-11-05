
import Foundation
import Essentials
import Clibgit2

public extension RepoID {
    enum HeadType {
        case unborn
        case attached(ReferenceID)
        case detached(OID, RepoID)
    }

    var HEAD : R<HeadType> {
        self.repo.if(\.headIsDetached,
                      then: { repo in repo.HEAD() | { Duo($0, repo).targetOID() } | { HeadType.detached($0, self)} },
                      else: { repo in repo.HEAD() | { HeadType.attached(ReferenceID(repoID: self, name: $0.nameAsReference))} }
        )
    }
}


public extension RepoID.HeadType {
    var asReference : R<ReferenceID> {
        switch self {
        case .attached(let ref):        return .success(ref)
        case .detached(_, let repoID):  return .success(ReferenceID(repoID: repoID, name: "HEAD"))
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    var asOID : R<OID> {
        switch self {
        case .attached(let ref): return ref.targetOID
        case .detached(let oid, _): return .success(oid)
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    var repoID: R<RepoID> {
        switch self {
        case .attached(let ref):        return .success(ref.repoID)
        case .detached(_, let repoID):  return .success(repoID)
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    func detach() -> R<()> {
        let repo = repoID | { $0.repo }
        return combine(repo, asOID) | { repo, oid in repo.setHEAD_detached(oid) }
    }
}
