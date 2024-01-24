
import Foundation

extension ExtendedStatus {
    struct Signature : Equatable {
        let entries : [String]
    }
    
    var signature : Signature { Signature(entries: status.map { $0.stagePath }) }
}
