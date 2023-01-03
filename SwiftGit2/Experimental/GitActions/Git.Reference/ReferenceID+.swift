
import Foundation
import Essentials
import Clibgit2

// TODO: custom name
// TODO: auto rename, probably name_remote

public extension ReferenceID {
    var tagInfo : R<Tag> {
        guard isTag else { return .wtf("reference shoud be tag: \(self.name)")}
        let repo = repoID.repo
        let ref = repo | { $0.reference(name: self.name) }
        let oid = combine(ref, repo) | { ref, repo in ref.with(repo).targetOID() }
        
        return combine(repo, oid) | { repo, oid in repo.tagLookup(oid: oid) }
    }
    
    func startTracking() -> R<()> {
        guard self.isRemote else { return .wtf("can't start tracking: reference is not remote: \(self)")}

        let upstreamName = name.split(separator: "/").dropFirst(2).joined(separator: "/")
        let newBranchName = name.split(separator: "/").dropFirst(3).joined(separator: "/")
        
        return repoID.repo.flatMap { repo in
            repo.branchLookup(name: name)
                .flatMap { remoteBranch in
                    repo.createBranch(from: .branch(remoteBranch), name: newBranchName, checkout: false, stashing: false)
                }
                .flatMap { $0.asBranch() }
            // set as HEAD
                .flatMap { repo.checkout(branch: $0, strategy: .Force, stashing: false) }
            // set HEAD branch's upstream to existing remote branch
                .flatMap { repo.HEAD() }
                .flatMap { $0.asBranch() }
                .flatMap { $0.setUpstream(name: upstreamName) }
                .flatMap { _ in .success(()) }
        }
    }
    
    func delete() -> R<()> {
        repoID.repo | { $0.reference(name: name) } | { $0.delete() }
    }
    
    func pushAsBranch(auth: Auth) -> R<Void> {
        guard let remote = self.remote else { return .wtf("not a remote") }
        let repo = repoID.repo
        return repo
        | { $0.remote(name: remote) }
        | { $0.push(refspec: ":refs/heads/\(self.displayName)", options: PushOptions(auth: auth)) }
    }

}
