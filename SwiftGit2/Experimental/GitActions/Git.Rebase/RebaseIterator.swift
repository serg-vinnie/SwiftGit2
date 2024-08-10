import Foundation
import Essentials
import Clibgit2

internal class RebaseIterator : ResultIterator {
    typealias Success = OID
    
    let rebase : Rebase
    let signature : Signature
    var operation : UnsafeMutablePointer<git_rebase_operation>?
    
    init(rebase: Rebase, sigature: Signature) {
        self.rebase = rebase
        self.signature = sigature
        self.operation = rebase.currentOperation
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
    
    func iterate(sigature: Signature) -> R<[OID]> {
        RebaseIterator(rebase: self, sigature: sigature).all()
    }
}
