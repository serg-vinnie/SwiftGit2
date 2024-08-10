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
    
    func next() -> R<OID?> {   // return nil to complete
        (rebase.next(operation: &operation) | { rebase.commit(signature: signature) } | { $0 })
            .flatMapError { error in
                if error.isGit2(func: "git_rebase_next", code: -31) {
                    return .success(nil)
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
