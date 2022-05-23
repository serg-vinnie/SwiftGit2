import Foundation
import Essentials


public struct GitCommit {
    public let repoID: RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
}


public extension GitCommit {
    func revert(commit: Commit) -> R<()> {
        self.repoID.repo.flatMap{ $0.commit(oid: commit.oid) }
            .flatMap{ commitFromRepo in
                self.repoID.repo.flatMap{ $0.revert(commit: commitFromRepo) }
            }
    }
    
    func cherryPick(commit: Commit) -> R<()> {
        //https://libgit2.org/libgit2/#HEAD/group/cherrypick/git_cherrypick
        return .success(())
    }
}
