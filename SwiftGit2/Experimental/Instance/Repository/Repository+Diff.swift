//
//  Repository+Diff.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 29.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension Repository {
    func hunksFrom(delta: Diff.Delta, options: DiffOptions = DiffOptions()) -> Result<[Diff.Hunk], Error> {
        let old = delta.oldFile != nil ? (try? blob(oid: delta.oldFile!.oid).get()) : nil
        let new = delta.newFile != nil ? (try? blob(oid: delta.newFile!.oid).get()) : nil

        return hunksBetweenBlobs(old: old, new: new, options: options)
    }
    
    func patchFrom(delta: Diff.Delta, options _: DiffOptions? = nil, reverse: Bool = false) -> Result<Patch, Error> {
        let oldFile = delta.oldFile
        let newFile = delta.newFile
        
        if oldFile == nil && newFile == nil {
            return .wtf("patchFrom: oldFile == nil & newFile == nil")
        }
        
        if oldFile == nil {
            return .wtf("oldFile == nil")
//            return blob(oid: newFile!.oid)
//                .flatMap{ Patch.fromBlobs(old: nil, oldPath: nil, new: $0, newPath: newFile!.path) }
        }
        
        if newFile == nil {
            return .wtf("newFile == nil")
//            return blob(oid: oldFile!.oid)
//                .flatMap{ Patch.fromBlobs(old: $0, oldPath: oldFile!.path, new: nil, newPath: nil) }
        }
        
        return combine( blob(oid: oldFile!.oid), blob(oid: newFile!.oid) )
                .flatMap{ Patch.fromBlobs(old: $0, oldPath: oldFile!.path, new: $1, newPath: newFile!.path) }
    }
    
    func blob(oid: OID) -> Result<Blob, Error> {
        var oid = oid.oid
        var blob_pointer: OpaquePointer?
        
        return _result({ Blob(blob_pointer!) }, pointOfFailure: "git_object_lookup") {
            git_object_lookup(&blob_pointer, self.pointer, &oid, GIT_OBJECT_BLOB)
        }
    }
}

public extension Repository {
    func hunkFrom(relPath: String) -> R<Diff.Hunk> {
        
        //let repo = self
        
        self.directoryURL
            .map{ $0.appendingPathComponent(relPath).path }
            .flatMap { self.blobCreateFromDisk(path: $0 )}
            .flatMap { self.blob(oid: $0) }
            .flatMap { self.diffBlobs(old: nil, new: $0) }
            .flatMap { $0.first.asNonOptional }
            .flatMap { $0.hunks.first.asNonOptional }
    }
}
