
import Foundation

public extension ExtendedStatus {
    struct Signature : Equatable {
        public let entries : [String]
    }
    
    var signature : Signature { Signature(entries: status.map { $0.stagePath }) }
}
