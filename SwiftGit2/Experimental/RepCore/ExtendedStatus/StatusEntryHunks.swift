//
//  StatusEntryHunks.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.12.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.

import Foundation
import Clibgit2

public struct StatusEntryHunks {
    public let staged       : [Diff.Hunk]
    public let unstaged     : [Diff.Hunk]
    public let incomplete   : Bool
}

extension StatusEntryHunks {
    var all : [Diff.Hunk] {
        staged.appending(contentsOf: unstaged)
            .sorted{ $0.newStart < $1.newStart }
    }
    
    public static func empty() -> StatusEntryHunks {
        return StatusEntryHunks(staged: [], unstaged: [], incomplete: false)
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
