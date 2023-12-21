
import Foundation
import Essentials
import Clibgit2

public struct TreeID {
    public let repoID: RepoID
    public let oid: OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}

public extension TreeID {
    var tree : R<Tree> { repoID.repo | { $0.treeLookup(oid: oid) } }
    
    var entries : R<[TreeID.Entry]> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.entries(repoID: repoID) } }
    }
    
    func walk() -> R<()> {
        tree | { $0.walk() }
    }
}


