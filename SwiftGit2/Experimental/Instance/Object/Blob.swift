//
//  Blob.swift
//  SwiftGit2-OSX
//
//  Created by loki on 30.11.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Blob: Object {
    public let pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_object_free(pointer)
    }
    
    public var oid: OID { OID(git_object_id(pointer).pointee) }
}

public extension Blob {
    var isBinary: Bool { git_blob_is_binary(pointer) == 1 }
    
    func content() -> R<String>{
        let buffPointer = git_blob_rawcontent(self.pointer)
        
        let size = git_blob_rawsize(pointer)
        
        let a = Buffer(data: buffPointer, size: size.bitWidth)
        
        return a.asString()
    }
}

public extension Repository {
//    func diffBlobs(old: Blob?, new: Blob?, options: DiffOptions = DiffOptions()) -> Result<[Diff.Delta], Error> {
//        var cb = options.callbacks
//        
//        return _result({ cb.deltas }, pointOfFailure: "git_diff_blobs") {
//            git_diff_blobs(old?.pointer, nil, new?.pointer, nil, &options.diff_options, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
//        }
//    }
    
    func hunksBetweenBlobs(old: Blob?, new: Blob?, options: DiffOptions = DiffOptions()) -> Result<HunksResult, Error> {
        var cb = options.callbacks
        
        if let old = old {
            if old.isBinary {
                return .success(.binary)
            }
        }
        
        if let new = new {
            if new.isBinary {
                return .success(.binary)
            }
        }
        
        return git_try("git_diff_blobs") {
            git_diff_blobs(old?.pointer, nil, new?.pointer, nil, &options.diff_options, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
        }.map { HunksResult(hunks: cb.deltas.first?.hunks ?? [], incomplete: false, IsBinary: false) }
            .flatMapError { error in
                if error.isGit2(func: "git_diff_blobs", code: Int((GIT2_HUNK_LINE_LIMIT_REACHED))) {
                    return .success(HunksResult(hunks: cb.deltas.first?.hunks ?? [], incomplete: true, IsBinary: false))
                }
                return .failure(error)
            }
//        return _result({ cb.deltas.first?.hunks ?? [] }, pointOfFailure: "git_diff_blobs") {
//            git_diff_blobs(old?.pointer, nil, new?.pointer, nil, &options.diff_options, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
//        }
    }
}
