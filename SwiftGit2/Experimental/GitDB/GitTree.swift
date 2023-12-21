
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
        print("walk start \(oid.oidShort)")
        let b =  repoID.repo | { $0.treeLookup(oid: oid) } | { $0.walk() }
        print("walk stop \(oid.oidShort)")
        return b
    }
}
