
import Foundation
import Clibgit2
import Essentials
import Parsing

public extension ReflogEntry {
    enum Target : Equatable, Hashable {
        case commit(OID)
        case branch(String)
    }
    
    enum Kind : Equatable, Hashable {
        case clone(String)
        case commit(OID)
        case checkout(Target,Target)
        
        case undefined
    }
}

public extension ReflogEntry {
    var kind : Kind {
        let message = self.message
        
        do {
            let message = try commitParser.parse(message)
            if let oid = OID(string: String(message)) {
                return .commit(oid)
            }
        } catch { }
        
        do {
            let (src,dst) = try checkoutParser.parse(message)
            let _src = OID(string: String(src))?.asReflogTarget ?? .branch(String(src))
            let _dst = OID(string: String(dst))?.asReflogTarget ?? .branch(String(dst))
            
            return .checkout(_src, _dst)
        } catch { }
        
        do {
            let url = try cloneParser.parse(message)
            return .clone(String(url))
        } catch { }
        
        return .undefined
    }
}

var commitParser = Parse {
    StartsWith("commit: ")
    Rest<String.SubSequence>()
}

var cloneParser = Parse {
    StartsWith("clone: from ")
    Rest<String.SubSequence>()
}

var checkoutParser = Parse {
    StartsWith("checkout: moving from ")
    Prefix { $0 != " " }
    " to "
    Rest<String.SubSequence>()
}

extension OID {
    var asReflogTarget : ReflogEntry.Target { .commit(self) }
}
