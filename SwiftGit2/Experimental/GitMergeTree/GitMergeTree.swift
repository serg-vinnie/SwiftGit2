
import Foundation
import Essentials

enum MergeSource {
    case commit(CommitID)
    case reference(ReferenceID)
}

struct GitMergeTree {
    let from : MergeSource
    let into : ReferenceID
}

extension GitMergeTree {
    struct RowDuo {
        let left  : Slot
        let right : Slot
    }
    
    enum Slot {
        case base(GitCommitBasicInfo)
        case commit(GitCommitBasicInfo)
        case branchFrom
        case mergeInto
        case empty
        case mergeTarget
    }
}

extension GitMergeTree.Slot {
    enum Kind {
        case source
        case destination
    }
}

extension GitMergeTree {
    var rows : R<[RowDuo]> {
        
        return .notImplemented
    }
}

fileprivate let WIDTH = 30

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
            
        case .mergeInto:        return "".fitIn(count: WIDTH - 1) + "↗️"
        case .branchFrom:       return "".fitIn(count: WIDTH - 1) + "↖️"
        case .mergeTarget:      return "🔯".fitIn(count: WIDTH)
        }
    }
}

fileprivate extension GitCommitBasicInfo {
    func nodeDesc(kind: GitMergeTree.Slot.Kind) -> String {
        switch kind {
        case .source:       _node + " " + _summary
        case .destination:  _summary + " " + _node
        }
    }
    
    var _node: String { "[\(author.name.nameInitials)]" }
    var _summary: String {
        return summary.fitIn(count: WIDTH)
    }
}

internal extension String {
    var nameInitials : String {
        split(byCharsIn: " ").map { $0.firstCharOrSpace }.joined().fitIn(count: 2).uppercased()
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
            return self.truncStart(length: count)
        } else if diff < 0 {
            return self + String(repeating: " ", count: abs(diff))
        }
        
        return self
    }
}
