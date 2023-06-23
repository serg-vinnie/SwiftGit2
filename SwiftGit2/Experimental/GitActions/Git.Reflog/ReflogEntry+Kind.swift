
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
        case pull(String)
        case commit(String)
        case commitInitial(String)
        case commitMerge(String)
        case checkout(Target,Target)
        case reset
        
        case undefined
    }
}

public extension ReflogEntry.Kind {
    var title : String {
        switch self {
        case .clone(_):         return "clone"
        case .pull(_):          return "pull"
        case .commit(_):        return "commit"
        case .commitInitial(_): return "commit"
        case .commitMerge(_):   return "commit"
        case .checkout(_, _):   return "checkout"
        case .undefined:        return "other"
        case .reset:            return "reset"
        }
    }
    
    var isCommit : Bool {
        switch self {
        case .commit(_): return true
        case .commitMerge(_): return true
        case .commitInitial(_): return true
        default: return false
        }
    }
}

public extension ReflogEntry {
    var kind : Kind {
        let message = self.message
        
        
        do {
            let msg = try commitParser.parse(message)
            return .commit(String(msg))
        } catch { }
        
        do {
            let msg = try commitInitParser.parse(message)
            return .commitInitial(String(msg))
        } catch { }
        
        do {
            let msg = try commitMergeParser.parse(message)
            return .commitMerge(String(msg))
        } catch { }
        
        do {
            let msg = try pullParser.parse(message)
            return .pull(String(msg))
        } catch { }
        
        if message.starts(with: "Fast Forward") {
            return .pull(message)
        }
        
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
        
        do {
            let _ = try resetParser.parse(message)
            return .reset
        } catch { }
        
        return .undefined
    }
}

var resetParser = Parse {
    StartsWith("reset: moving to")
    Rest<String.SubSequence>()
}

var commitParser = Parse {
    StartsWith("commit: ")
    Rest<String.SubSequence>()
}

var commitMergeParser = Parse {
    StartsWith("commit (merge): ")
    Rest<String.SubSequence>()
}

var commitInitParser = Parse {
    StartsWith("commit (initial): ")
    Rest<String.SubSequence>()
}

var pullParser = Parse {
    StartsWith("pull: ")
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
