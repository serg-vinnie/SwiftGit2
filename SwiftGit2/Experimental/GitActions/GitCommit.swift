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
    
    func getLastCommitsDescrForUser(name: String, email: String, count: Int = 10) -> R<[String]> {
        repoID.repo
            .flatMap{ $0.commitsFromHead(num:300) }
            .map {
                $0.filter{ $0.commiter.name.asString() == name || $0.commiter.email.asString() == email }
            }
            .map{ $0.map{ $0.description } }
            .map{ $0.first(count).map{ $0 } }
    }
}
