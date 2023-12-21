
import Foundation
import Essentials
import Clibgit2

public extension GitDB {
    struct Tree {
        let repoID: RepoID
        let oid: OID
        
        public init(repoID: RepoID, oid: OID) {
            self.repoID = repoID
            self.oid = oid
        }
    }
}

public extension GitDB.Tree {
    var tree : R<Tree> { repoID.repo | { $0.treeLookup(oid: oid) } }
    
    var entries : R<[GitDB.Tree.Entry]> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.entries(repoID: repoID) } } 
    }
    
    func walk() -> R<()> {
        tree | { $0.walk() }
    }
}


public extension GitDB.Tree {
    struct Entry : CustomStringConvertible {
        enum Kind : String {
            case blob
            case tree
            case wtf
        }
        
        let repoID: RepoID
        let name: String
        let oid: OID
        let kind: Kind
        
        public var description: String { "\(oid.oidShort) \(name) \(kind)" }
    }
}
