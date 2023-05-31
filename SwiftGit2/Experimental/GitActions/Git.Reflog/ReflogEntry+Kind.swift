
import Foundation
import Clibgit2
import Essentials
import Parsing

public extension ReflogEntry {
    enum Target {
        case commit(OID)
        case branch(String)
    }
    
    enum Kind {
        case checkout(Target,Target)
        case commit
        case undefined
    }
}

extension ReflogEntry {
    var kind : Kind {
        
        return .undefined
    }
}

var reflogEntryParser = Many {
    Parse {
        StartsWith("checkout: moving from ")
        Prefix { $0 != " " }
        " to"
    }
}
