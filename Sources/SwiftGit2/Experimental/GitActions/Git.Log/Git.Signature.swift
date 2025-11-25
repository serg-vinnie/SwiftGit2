import Foundation
import Clibgit2

public struct GitSignature {
    public let name    : String
    public let email   : String
    public let when    : Date
    
    init(_ signature: git_signature) {
        self.name = signature.name.asString()
        self.email = signature.email.asString()
        self.when  = signature.when.time.asDate()
    }
    
    init(name: String, email: String, when: Date) {
        self.name = name
        self.email = email
        self.when = when
    }
}

fileprivate extension git_time_t {
    func asDate() -> Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}
