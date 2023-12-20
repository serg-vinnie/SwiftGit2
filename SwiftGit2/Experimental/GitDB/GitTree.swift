
import Foundation
import Essentials
import Clibgit2

public struct GitTree {
    let repoID: RepoID
    let oid: OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}

public extension GitTree {
    func walk() -> R<()> {
        repoID.repo | { $0.treeLookup(oid: oid) } | { $0.walk() }
    }
}
