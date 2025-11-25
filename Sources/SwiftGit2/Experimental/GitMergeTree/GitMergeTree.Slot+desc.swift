

import Foundation
import Essentials

//extension Array where Element == GitMergeTree.RowDuo {
//    var description: String {
//        self.map { $0.description }.joined(separator: "")
////        left.description(kind: .source) + "   " + right.description(kind: .destination)
//    }
//}

extension GitMergeTree.RowDuo : CustomStringConvertible {
    public var description: String {
        left.description(kind: .source) + "   " + right.description(kind: .destination)
    }
}

public extension GitMergeTree.Slot {
    enum Kind {
        case source
        case destination
    }
}

fileprivate let WIDTH = 20

extension GitMergeTree.Slot {
    func description(kind: GitMergeTree.Slot.Kind) -> String {
        switch self {
        case .base(let info):   return info.nodeDesc(kind: kind)
        case .commit(let info): return info.nodeDesc(kind: kind)
        case .empty:            return
            switch kind {
            case .source:       "".fitIn(count: WIDTH - 1) + "|"
            case .destination:  "|".fitIn(count: WIDTH)
            }
            
        case .mergeInto:        return "".fitIn(count: WIDTH + 2) + "╔  "
        case .branchFrom:       return "".fitIn(count: WIDTH + 2) + "╚  "
        case .mergeTarget:      return " 🔯".fitIn(count: WIDTH)
        }
    }
}

fileprivate extension GitCommitBasicInfo {
    func nodeDesc(kind: GitMergeTree.Slot.Kind) -> String {
        switch kind {
        case .source:       _summary + " " + _node
        case .destination:  _node + " " + _summary
        }
    }
    
    var _node: String { "[\(author.name.nameInitials)]" }
    var _summary: String {
        return summary.fitIn(count: WIDTH)
    }
}

internal extension String {
    var nameInitials : String {
        split(byCharsIn: " ").map { $0.firstCharOrSpace }.joined().fitIn(count: 2).uppercased().trimmingCharacters(in: ["…"])
    }
    
    var firstCharOrSpace : String {
        if let first = self.first {
            return String(first)
        }
        return " "
    }
    
    func fitIn(count: Int) -> String {
        let diff = self.count - count
        
        if diff > 0 {
            return self.truncEnd(length: count).trimmingCharacters(in: ["…"])
        } else if diff < 0 {
            return self + String(repeating: " ", count: abs(diff))
        }
        
        return self
    }
}
