//
//  StatusEntryHunks.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.12.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.

import Foundation
import Clibgit2

public struct HunksResult {
    public let hunks        : [Diff.Hunk]
    public let incomplete   : Bool
    static var empty : HunksResult { HunksResult(hunks: [], incomplete: false) }
}

public struct StatusEntryHunks {
    public let staged       : HunksResult
    public let unstaged     : HunksResult
}

extension StatusEntryHunks {
    var all : [Diff.Hunk] {
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
