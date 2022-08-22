import Foundation
import Essentials


public struct GitStasher {
    public enum State : Equatable {
        case empty
        case stashed(OID)
        case unstashed
        var isStashed : Bool { guard case .stashed(_) = self else { return false }; return true }
    }
    
    public let state : State
    public let repo: Repository
    
    public init(repo: Repository, state: State = .empty) {
        self.repo = repo
        self.state = state
    }
    
    public func wrap<T>(skip: Bool = false, _ block: ()-> R<T>) -> R<T> {
        if skip {
            return block()
        }
        switch push() {
        case .success(let me):
            let result = block()
            return result | { _ in me.pop() } | { _ in result }
        case .failure(let error):
            return .failure(error)
        }
    }
}

public extension GitStasher {
    func push() -> R<Self> {
        let isEmpty = repo.status() | { $0.count == 0 }

        return isEmpty.flatMap { isEmpty in
            if isEmpty || repo.headIsUnborn {
                return .success(GitStasher(repo: repo, state: .empty))
            } else {
                return stash().map { GitStasher(repo: repo, state: .stashed($0)) }
            }
        }
    }
    
    func pop() -> R<Self> {
        switch state {
        case .stashed(let oid):
            return repo.repoID | { repoID in
                GitStash(repoID: repoID).pop(oid: oid)  | { _ in GitStasher(repo: self.repo, state: .unstashed) }
            }
        default: return .success(self)
        }
    }
}


private extension GitStasher {
    func stash() -> R<OID> {
        let signature = Signature(name: "GitStasher", email: "support@taogit.com")
        return repo.repoID | { repoID in GitStash(repoID: repoID)
            .save(signature: signature, message: "atomatic stash", flags: .includeUntracked)
        }
    }
}
