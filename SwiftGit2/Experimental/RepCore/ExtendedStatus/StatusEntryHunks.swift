
import Foundation
import Clibgit2

public struct StatusEntryHunks {
    public let staged       : HunksResult
    public let unstaged     : HunksResult
    
    public var isBinary : Bool { staged.IsBinary || unstaged.IsBinary }
}

public struct HunksResult {
    public let hunks        : [Diff.Hunk]
    public let incomplete   : Bool
    public let IsBinary       : Bool
    static var empty : HunksResult { HunksResult(hunks: [], incomplete: false, IsBinary: false) }
    static var binary : HunksResult { HunksResult(hunks: [], incomplete: false, IsBinary: true)}
}

extension StatusEntryHunks {
    public var all : [Diff.Hunk] {
        staged.hunks.appending(contentsOf: unstaged.hunks)
            .sorted{ $0.newStart < $1.newStart }
    }
    
    public static func empty() -> StatusEntryHunks {
        return StatusEntryHunks(staged: .empty, unstaged: .empty)
    }
}

extension Diff.Hunk : CustomStringConvertible {
    public var description: String {
        lines.map{ $0.content }.compactMap{ $0 }.joined()
    }
    
    func print() {
        Swift.print(self)
    }
}
