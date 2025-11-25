//
//  Blame.swift
//  SwiftGit2-OSX
//
//  Created by Sergiy Vynnychenko on 25.09.2024.
//  Copyright © 2024 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public final class Blame: InstanceProtocol, DuoUser {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_blame_free(pointer)
    }
}
    
public extension Blame {
    var hunkCount : UInt32 { git_blame_get_hunk_count(self.pointer) }
    
    func hunk(idx: UInt32) -> R<git_blame_hunk> {
        if let b = git_blame_get_hunk_byindex(self.pointer, idx) {
            return .success(b.pointee)
        } else {
            return .wtf("hunk not found for idx: \(idx)")
        }
    }
    
    func hunk(line: Int) -> R<git_blame_hunk> {
        if let b = git_blame_get_hunk_byline(self.pointer, line) {
            return .success(b.pointee)
        } else {
            return .wtf("hunk not found for line: \(line)")
        }
    }
}

extension Repository {
    func blame(path: String, options: BlameOptions) -> R<Blame> {
        git_instance(of: Blame.self, "git_blame_file") { pointer in
            git_blame_file(&pointer,self.pointer,path, &options.options)
        }
    }
}

public class BlameOptions {
    var options = git_blame_options()
    
    public init(flags: GitBlame.Flags = [.normal], commitOID: OID?) {
        git_blame_options_init(&options, UInt32(GIT_BLAME_OPTIONS_VERSION))
        options.flags = flags.rawValue
        if let oid = commitOID?.oid {
            options.newest_commit = oid
        }
    }
}

public extension GitBlame {
    struct Flags: OptionSet {
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        nonisolated(unsafe) public static let normal                        = Flags(rawValue: GIT_BLAME_NORMAL.rawValue)
        nonisolated(unsafe) public static let trackCopiesSameFile           = Flags(rawValue: GIT_BLAME_TRACK_COPIES_SAME_FILE.rawValue)
        nonisolated(unsafe) public static let trackCopiesSameCommitMoves    = Flags(rawValue: GIT_BLAME_TRACK_COPIES_SAME_COMMIT_MOVES.rawValue)
        nonisolated(unsafe) public static let trackCopiesSameCommitCopies   = Flags(rawValue: GIT_BLAME_TRACK_COPIES_SAME_COMMIT_COPIES.rawValue)
        nonisolated(unsafe) public static let trackCopiesAnyCommitCopies    = Flags(rawValue: GIT_BLAME_TRACK_COPIES_ANY_COMMIT_COPIES.rawValue)
        nonisolated(unsafe) public static let firstParent                   = Flags(rawValue: GIT_BLAME_FIRST_PARENT.rawValue)
        nonisolated(unsafe) public static let useMailmap                    = Flags(rawValue: GIT_BLAME_USE_MAILMAP.rawValue)
        nonisolated(unsafe) public static let ignoreWhitespace              = Flags(rawValue: GIT_BLAME_IGNORE_WHITESPACE.rawValue)
        
    }
}
