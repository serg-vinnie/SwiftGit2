//
//  Stash.swift
//  SwiftGit2Tests
//
//  Created by UKS on 15.05.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

//public extension Repository {
//    func stashForeach() -> Result<[Diff.Delta], Error> {
//        var cb = DiffEachCallbacks()
//
//        return _result({ cb.deltas }, pointOfFailure: "git_diff_blobs") {
//            git_diff_blobs(old?.pointer, nil, new?.pointer, nil, &options.diff_options, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
//        }
//    }
//}

class StashCallbacks {
    
    let each_file_cb: git_stash_cb = { index, message, id, payload   in
//        callbacks.unsafelyUnwrapped
//            .bindMemory(to: StashCallbacks.self, capacity: 1)
//            .pointee
//            .file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)
        
        return 0
    }
}

struct StashFlags: OptionSet {
    public let rawValue: UInt32
    
    public static let defaultt = StashFlags(rawValue: GIT_STASH_DEFAULT.rawValue)
    public static let keepIndex = StashFlags(rawValue: GIT_STASH_KEEP_INDEX.rawValue)
    public static let includeUntracked = StashFlags(rawValue: GIT_STASH_INCLUDE_UNTRACKED.rawValue)
    public static let includeIgnored = StashFlags(rawValue: GIT_STASH_INCLUDE_IGNORED.rawValue)
}
