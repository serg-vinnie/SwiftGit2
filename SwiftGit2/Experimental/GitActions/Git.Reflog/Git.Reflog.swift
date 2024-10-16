
import Foundation
import Essentials
import Clibgit2


public struct GitReflog {
    let repoID: RepoID
    let name: String
    
    public init(repoID: RepoID, name: String = "HEAD") {
        self.repoID = repoID
        self.name = name
    }
    
    public var iterator : R<GitReflogIterator> { reflog | { .init(reflog: $0, repoID: repoID) } }
    
    fileprivate var reflog : R<Reflog> { repoID.repo | { $0.reflog(name: self.name) } }
}

public extension GitReflog {
    var entryCount : R<Int> { reflog | { $0.entryCount } }
    
    func append(signature: Signature, oid: OID, msg: String) -> R<Void> {
        reflog | { $0.append(signature: signature, oid: oid, msg: msg) }
    }
}
