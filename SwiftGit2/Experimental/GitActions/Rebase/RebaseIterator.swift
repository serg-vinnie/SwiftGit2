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
    }
    
    func next() -> R<OID?> {   // return nil to complete
        rebase.next(operation: &operation) | { rebase.commit(signature: signature) } | { $0 }
    }
}

extension Rebase {
    
    func iterate(sigature: Signature) -> R<Void> {
        RebaseIterator(rebase: self, sigature: sigature).all().asVoid
    }
}
