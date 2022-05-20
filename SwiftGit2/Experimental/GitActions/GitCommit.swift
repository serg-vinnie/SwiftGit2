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
        self.repoID.repo.flatMap{ $0.revert(commit: commit) }
    }
}
