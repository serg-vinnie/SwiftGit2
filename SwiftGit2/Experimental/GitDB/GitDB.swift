
import Foundation
import Essentials
import Clibgit2

public struct GitDB {
    let repoID: RepoID
    
    public init(repoID: RepoID) { self.repoID = repoID }
}

public extension GitDB {
    var objects : R<[String]> {
        return XR.Shell.Git(repoID: repoID).run(args: ["cat-file", "--batch-check", "--batch-all-objects", "--unordered"])
            .map { $0.split(byCharsIn: "\n") }
    }
}
