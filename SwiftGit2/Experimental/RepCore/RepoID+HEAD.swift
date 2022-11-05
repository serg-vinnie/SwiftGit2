
import Foundation
import Essentials
import Clibgit2

public extension RepoID {
    enum HeadType {
        case attached(ReferenceID)
        case detached(OID, RepoID)
        
        public var asReference : ReferenceID {
            switch self {
            case .attached(let ref):        return ref
            case .detached(_, let repoID):  return ReferenceID(repoID: repoID, name: "HEAD")
            }
        }
        
        public var asOID : R<OID> {
            switch self {
            case .attached(let ref): return ref.targetOID
            case .detached(let oid, _): return .success(oid)
            }
        }
    }

    var HEAD : R<HeadType> {
        self.repo.if(\.headIsDetached,
                      then: { repo in repo.HEAD() | { Duo($0, repo).targetOID() } | { HeadType.detached($0, self)} },
                      else: { repo in repo.HEAD() | { HeadType.attached(ReferenceID(repoID: self, name: $0.nameAsReference))} }
        )
    }
}
