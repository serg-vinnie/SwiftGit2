
import Foundation
import Essentials
import Clibgit2

public extension RepoID {
    enum HeadType : Equatable {
        case unborn
        case attached(ReferenceID)
        case detached(CommitID)
    }
    
    var headTreeID: R<TreeID> {
        self.repo | { $0.headCommit() } | { $0.treeOID } | { TreeID(repoID: self, oid: $0) }
    }

    var HEAD : R<HeadType> {
        repo
            .if(\.headIsUnborn,
                 then: { _ in .success(.unborn) },
                 else: { _ in self._HEAD }
            )
            
    }
    
    private var _HEAD : R<HeadType> {
        self.repo
            .if(\.headIsDetached,
                 then: { repo in repo.HEAD() | { Duo($0, repo).targetOID() } | { HeadType.detached(CommitID(repoID: self, oid: $0))} },
                 else: { repo in repo.HEAD() | { HeadType.attached(ReferenceID(repoID: self, name: $0.nameAsReference))} }
            )
    }
}

public extension RepoID.HeadType {
    var asMergeSource : R<MergeSource> {
        switch self {
        case .attached(let refID):      return .success(.reference(refID))
        case .detached(let commitID):   return .success(.commit(commitID))
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    var asReference : R<ReferenceID> {
        switch self {
        case .attached(let ref):        return .success(ref)
        case .detached(let commitID):   return .success(ReferenceID(repoID: commitID.repoID, name: "HEAD"))
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    var asOID : R<OID> {
        switch self {
        case .attached(let ref):        return ref.targetOID
        case .detached(let commitID):   return .success(commitID.oid)
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    var repoID: R<RepoID> {
        switch self {
        case .attached(let ref):        return .success(ref.repoID)
        case .detached(let commitID):   return .success(commitID.repoID)
        case .unborn:                   return .wtf("Head is unborn")
        }
    }
    
    func detach() -> R<()> {
        let repo = repoID | { $0.repo }
        return combine(repo, asOID) | { repo, oid in repo.setHEAD_detached(oid) }
    }
}
