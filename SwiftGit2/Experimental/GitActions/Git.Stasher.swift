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
    public let repoID: RepoID
    
    public init(repoID: RepoID, state: State = .empty) {
        self.repoID = repoID
        self.state = state
    }
}

public extension GitStasher {
    func push() -> R<Self> {
        let isEmpty = repoID.repo | { $0.status() } | { $0.count == 0 }
        let headIsUnborn = repoID.repo  | { $0.headIsUnborn }
        return combine(isEmpty, headIsUnborn).flatMap { isEmpty, isUnborn in
            if isEmpty || isUnborn {
                return .success(GitStasher(repoID: repoID, state: .empty))
            } else {
                return stash().map { GitStasher(repoID: repoID, state: .stashed($0)) }
            }
        }
    }
    
    func pop() -> R<Self> {
        switch state {
        case .stashed(let oid): return GitStash(repoID: repoID).pop(oid: oid) | { _ in GitStasher(repoID: repoID, state: .unstashed) }
        default: return .success(self)
        }
    }
}


private extension GitStasher {
    func stash() -> R<OID> {
        let signature = Signature(name: "GitStasher", email: "support@taogit.com")
        return GitStash(repoID: repoID)
            .save(signature: signature, message: "atomatic stash")
    }
}
