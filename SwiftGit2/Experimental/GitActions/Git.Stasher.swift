import Foundation
import Essentials


public struct GitStasher {
    public enum State : Equatable {
        case empty
        case stashed(String)
        case unstashed
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
        let statusIsEmpty = repoID.repo | { $0.status() } | { $0.count == 0 }
        
        
        return statusIsEmpty.flatMap { isEmpty in
            if isEmpty {
                return .success(GitStasher(repoID: repoID, state: .empty))
            } else {
                return .notImplemented
            }
        }
    }
}
