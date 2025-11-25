//
//  DiffOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class DiffOptions {
    var diff_options = git_diff_options()
    let pathspec: [String]
    let linesPerHunkLimit : Int
    
    var callbacks : DiffEachCallbacks { DiffEachCallbacks(linesPerHunkLimit: linesPerHunkLimit) }

    public init(pathspec: [String] = [], linesPerHunkLimit: Int = -1) {
        self.pathspec = pathspec
        self.linesPerHunkLimit = linesPerHunkLimit
        
        let result = git_diff_options_init(&diff_options, UInt32(GIT_DIFF_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
        
//        diff_options.flags |=  GIT_DIFF_DISABLE_PATHSPEC_MATCH.rawValue
    }
}

extension DiffOptions {
    func with_diff_options<T>(_ body: (inout git_diff_options) -> T) -> T {
        if pathspec.isEmpty {
            return body(&diff_options)
        } else {
            return pathspec.with_git_strarray { strarray in
                diff_options.pathspec = strarray
                return body(&diff_options)
            }
        }
    }
}


class DiffEachCallbacks {
    let linesPerHunkLimit : Int
    var deltas       = [Diff.Delta]()
    
    fileprivate init(linesPerHunkLimit: Int) {
        self.linesPerHunkLimit = linesPerHunkLimit
    }
    

    let each_file_cb: git_diff_file_cb = { delta, progress, callbacks in
        callbacks.unsafelyUnwrapped
            .bindMemory(to: DiffEachCallbacks.self, capacity: 1)
            .pointee
            .file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)

        return 0
    }

    let each_line_cb: git_diff_line_cb = { _, _, line, callbacks in
        let _line = Diff.Line(line.unsafelyUnwrapped.pointee)
        let _cb = callbacks.unsafelyUnwrapped
            .bindMemory(to: DiffEachCallbacks.self, capacity: 1)
            .pointee
        
        return _cb.line(line: _line)
    }

    let each_hunk_cb: git_diff_hunk_cb = { _, hunk, callbacks in
        callbacks.unsafelyUnwrapped
            .bindMemory(to: DiffEachCallbacks.self, capacity: 1)
            .pointee
            .hunk(hunk: Diff.Hunk(hunk.unsafelyUnwrapped.pointee))

        return 0
    }

    private func file(delta: Diff.Delta, progress _: Float32) {
        deltas.append(delta)
    }

    private func hunk(hunk: Diff.Hunk) {
        guard let _ = deltas.last else { assert(false, "can't add hunk before adding delta"); return }

        deltas[deltas.count - 1].hunks.append(hunk)
    }

    private func line(line: Diff.Line) -> Int32 {
        guard let _ = deltas.last else { assert(false, "can't add line before adding delta"); return -1}
        guard let _ = deltas.last?.hunks.last else { assert(false, "can't add line before adding hunk"); return -1}
        
        let deltaIdx = deltas.count - 1
        let hunkIdx = deltas[deltaIdx].hunks.count - 1
        
        if self.linesPerHunkLimit > 0 {
            if  deltas[deltaIdx].hunks[hunkIdx].lines.count >=  self.linesPerHunkLimit {
                return GIT2_HUNK_LINE_LIMIT_REACHED
            }
        }
        
        deltas[deltaIdx].hunks[hunkIdx].lines.append(line)
        
        return 0
    }
}

let GIT2_HUNK_LINE_LIMIT_REACHED : Int32 = -10000420
