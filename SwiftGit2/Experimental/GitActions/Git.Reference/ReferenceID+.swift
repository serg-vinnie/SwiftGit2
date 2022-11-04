
import Foundation
import Essentials
import Clibgit2

// TODO: 
public extension ReferenceID {
    func startTracking() -> R<()> {
        guard self.isRemote else { return .wtf("")}

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
}
