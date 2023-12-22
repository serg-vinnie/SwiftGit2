
import Foundation
import Essentials
import Clibgit2

public struct TreeID : Hashable {
    public let repoID: RepoID
    public let oid: OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}

public extension TreeID {
    internal var tree : R<Tree> { repoID.repo | { $0.treeLookup(oid: oid) } }
    
    var entries : R<[TreeID.Entry]> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.entries(repoID: repoID) } }
    }
    
    func walk() -> R<()> {
        tree | { $0.walk() }
    }
    
    func extract(at: URL) -> R<()> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.iteratorEntries(repoID: repoID, url: at) } }
                    | { $0 | { $0.extract() } } | { _ in ()}
    }
}


