import Foundation
import Essentials
import Clibgit2

internal class RebaseIterator : ResultIterator {
    typealias Success = OID
    
    let rebase : Rebase
    let repo: Repository
    let signature : Signature
    let options: RebaseOptions
    var operation : UnsafeMutablePointer<git_rebase_operation>?
    
    init(rebase: Rebase, repo: Repository, sigature: Signature, options: RebaseOptions) {
        self.rebase = rebase
        self.repo = repo
        self.signature = sigature
        self.options = options
    }
    
    func getReadyToCommit() -> R<Void> {
        let hasConflicts = repo.index() | { $0.hasConflicts }
        switch hasConflicts {
        case .failure(let error): return .failure(error)
        case .success(let conflicted):
            if conflicted {
                return .failure(WTF("rebase.conflicted"))
            }
        }
        
        return repo.stage(.all).asVoid
    }
    
    func next() -> R<OID?> {   // return nil to complete
        (rebase.next(operation: &operation) | { getReadyToCommit() } | { rebase.commit(signature: signature) } | { $0 })
            .flatMapError { error in
                if error.isGit2(func: "git_rebase_next", code: -31) {
                    return .success(nil)
                }
                // if this patch has already been applied (if you do two identical commits)
                // skip the commit
                if error.isGit2(func: "git_rebase_commit", code: -18) {
                    return self.next()
                }
                return .failure(error)
            }
    }
}

extension Rebase {
    
    func iterate(repo: Repository, sigature: Signature, options: RebaseOptions) -> R<[OID]> {
        RebaseIterator(rebase: self, repo: repo, sigature: sigature, options: options).all()
    }
}
