
import Foundation
import Essentials
import Clibgit2
import DequeModule

public struct GitLog {
    public let refID : ReferenceID
    public init(refID: ReferenceID) { self.refID = refID }
    
    public func oids(count: Int) -> R<[OID]> { refID.repoID.repo | { $0.log(ref: refID.name, count: count) } }
    public var  oids              : R<[OID]> { refID.repoID.repo | { $0.log(ref: refID.name) } }

}

public class RefLogCache {
    public let ref : ReferenceID
    public var deque = Deque<OID>()
    
    public init(ref: ReferenceID, prefetch cout: Int) {
        self.ref = ref
        _ = load(cout)
    }
    
    public func load(_ count: Int) -> R<()> {
        guard count > 0 else { return .success(()) }
        deque.reserveCapacity(deque.count + count)
        return next(count)
            .onSuccess { deque.append(contentsOf: $0) }
            .asVoid
    }
    
    func next(_ count: Int) -> R<[OID]> {
        if let oid = deque.last {
            return ref.repoID.repo | { $0.log(oid: oid, count: count + 1) } | { Array($0.dropFirst()) }
        } else {
            return ref.repoID.repo | { $0.log(ref: ref.name, count: count) }
        }
    }
    
//    @discardableResult
//    public func fetchHEAD() -> R<[OID]> {
//        (ref.repoID.repo | { $0.logHEAD() })
//    }
//
//    public func fetchHEAD_Commits() -> R<[Commit]> {
//        (ref.repoID.repo | { repo in repo.logHEAD() | { $0 | { repo.commit(oid: $0) } } })
//    }
}

fileprivate extension Repository {
    func log(ref: String) -> R<[OID]> {
        Revwalk.new(in: self) | { $0.push(ref: ref) } | { $0.all() }
    }
    
    func log(ref: String, count: Int) -> R<[OID]> {
        Revwalk.new(in: self) | { $0.push(ref: ref) } | { $0.next(count: count) }
    }
    
    func log(oid: OID, count: Int) -> R<[OID]> {
        Revwalk.new(in: self) | { $0.push(oid: oid) } | { $0.next(count: count) }
    }
    
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
