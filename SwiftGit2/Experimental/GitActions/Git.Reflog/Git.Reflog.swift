
import Foundation
import Essentials
import Clibgit2
//import DequeModule

public struct GitReflog {
    let repoID: RepoID
    let name: String
    
    public init(repoID: RepoID, name: String = "HEAD") {
        self.repoID = repoID
        self.name = name
    }
    
    fileprivate var reflog : R<Reflog> { repoID.repo | { $0.reflog(name: self.name) } }
}

public extension GitReflog {
    var entryCount : R<Int> { reflog | { $0.entryCount } }
}
