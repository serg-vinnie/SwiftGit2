
import Foundation
import Essentials
import Clibgit2
import Foundation

public extension TreeID {
    struct Entry : CustomStringConvertible {
        enum Kind : String {
            case blob
            case tree
            case wtf
        }
        
        let treeID: TreeID
        let name: String
        let oid: OID
        let kind: Kind
        
        public var description: String { "\(oid.oidShort) \(name) \(kind)" }
    }
}
