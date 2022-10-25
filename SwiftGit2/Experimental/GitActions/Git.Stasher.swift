import Foundation
import Essentials


public struct GitStasher {
    public enum State : Equatable {
        case empty
        case tag(String)
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
        if repo.headIsUnborn {
            return .success(GitStasher(repo: repo, state: .empty))
        } else {
            return repo
                .status()
                //.map { !$0.isEmpty }
                .if(\.isEmpty,
                     then: { _ in   .success(GitStasher(repo: repo, state: .empty)) },
                     else: { _ in
                                    stash()
                                        .map { GitStasher(repo: repo, state: .stashed($0)) }
                                        .flatMapError { err in
                                            if err.isGit2(func: "git_stash_save", code: -3) {
                                                return .success(GitStasher(repo: repo, state: .empty))
                                            } else {
                                                return .failure(err)
                                            }
                                        }
                })
            
//            return stash()
//                .map { GitStasher(repo: repo, state: .stashed($0)) }
//                .flatMapError { err in
//                    if err.isGit2(func: "git_stash_save", code: -3) {
//                        return .success(GitStasher(repo: repo, state: .empty))
//                    } else {
//                        return .failure(err)
//                    }
//                }
        }
    }
    
    func pop() -> R<Self> {
        let opt = StashApplyOptions(flags: .reinstateIndex)
        
        switch state {
        case .stashed(let oid):
            return repo.repoID | { repoID in
                GitStash(repoID: repoID).pop(oid: oid, options: opt)  | { _ in GitStasher(repo: self.repo, state: .unstashed) }
            }
        default: return .success(self)
        }
    }
}


private extension GitStasher {
    func stash() -> R<OID> {
        let tag : String
        if case .tag(let t) = self.state {
            tag = " " + t
        } else {
            tag = ""
        }
        
        
        let signature = Signature(name: "GitStasher", email: "support@taogit.com")
        return repo.repoID | { repoID in GitStash(repoID: repoID)
            .save(signature: signature, message: "auto stash\(tag)", flags: .includeUntracked)
        }
    }
}
