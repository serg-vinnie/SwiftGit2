
import Foundation
import Essentials
import Clibgit2
import DequeModule

public struct GitLog {
    public let repoID : RepoID
    init(repoID: RepoID) { self.repoID = repoID }
}

public class LogCache {
    public let repoID : RepoID
    public var deque = Deque<OID>()
    
    public init(repoID: RepoID) {
        self.repoID = repoID
        //deque.reserveCapacity(5000)
    }
    
    @discardableResult
    public func fetchHEAD() -> R<[OID]> {
        (repoID.repo | { $0.logHEAD() })
    }
    
    public func fetchHEAD_Commits() -> R<[Commit]> {
        (repoID.repo | { repo in repo.logHEAD() | { $0 | { repo.commit(oid: $0) } } })
    }
}

extension Repository {
    func log(range: String) -> R<[OID]> {
        Revwalk.new(in: self) | { $0.push(range: range) } | { $0.all() }
    }
    
    func logHEAD(count: Int = 0) -> R<[OID]> {
        if count > 0 {
            return log(range: "HEAD~\(count)..HEAD")
        } else {
            return Revwalk.new(in: self) | { $0.pushHead() } | { $0.all() }
        }
    }
}
