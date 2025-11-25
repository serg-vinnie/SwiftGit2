
import Foundation
import Essentials
import Clibgit2
//import DequeModule

public extension GitLog {
    func filter<T: Equatable>(path: KeyPath<Commit,T>, equals: T, depth: Int) -> R<[CommitID]> {
        return self.oids(count: depth)
                        | { $0 | { oid in CommitID(repoID: refID.repoID, oid: oid) } }
                        | { $0.filter { $0.commit | { $0[keyPath: path] == equals }  } }
    }
}

extension Array {
    func filter(_ block: (Element)->R<Bool>) -> R<Self> {
        var out = Self()
        for element in self {
            switch block(element) {
            case .success(let condition):
                if condition {
                    out.append(element)
                }
            case .failure(let error):
                return .failure(error)
            }
        }
        return .success(out)
    }
}
