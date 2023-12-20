//
//  Tree.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Tree: InstanceProtocol {
    public var pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_tree_free(pointer)
    }
}

fileprivate class TreeEntry {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
}

extension TreeEntry {
//    var name : String { git_tree_entry_name(self.pointer).asSwiftString }
//    var type : git_object_t { git_tree_entry_type(self.pointer) }
    var oid  : OID { OID(git_tree_entry_id(self.pointer).pointee) }
}


public extension Tree {
    var oid : OID { OID(git_tree_id(self.pointer).pointee) }
}

fileprivate class GitTreePayload : GitPayload {
    var oids = [OID]()
}

func treeCB(_ root: UnsafePointer<Int8>?, _ tree_entry: OpaquePointer?, _ payload: UnsafeMutableRawPointer?) -> (Int32) {
    guard let _p = tree_entry else { return -1 }
    guard let payload = payload else { return -1 }
    let entry = TreeEntry(_p)
    let root = root.flatMap(String.init(validatingUTF8:)) ?? "WTF"
    let _payload = GitTreePayload.unretained(pointer: payload)
    
    _payload.oids.append(entry.oid)
//    print("root: \(root), entry: \(entry.oid)")
    
    return 0
}

public extension Tree {
    func walk() -> R<Void> {
        let p = GitTreePayload()
        let _p = p.toRetainedPointer()
        defer {
            GitTreePayload.release(pointer: _p)
        }
        
        return git_try("git_tree_walk") {
            git_tree_walk(self.pointer, GIT_TREEWALK_PRE, treeCB, _p)
        } //.map { _ in () }
    }
//    func blobLookup(byPath: String) -> R<Blob>{
//        var pointer: OpaquePointer?
//
//        return _result( { Blob(pointer!) }, pointOfFailure: "git_object_lookup_bypath") {
//            byPath.withCString { path in
//                git_object_lookup_bypath(&pointer, self.pointer, path, git_object_t(rawValue: 3) ) // raw 3 means blob
//            }
//        }
//
//    }
    
//    func entry(byPath: String) -> R<Blob>{
//        var pointer: OpaquePointer?
//        
//        return _result( { RepoTreeEntry(pointer!) }, pointOfFailure: "git_object_lookup_bypath") {
//            byPath.withCString { path in
//                git_tree_entry_bypath(&pointer, self.pointer, path, git_object_t(rawValue: 3) ) // raw 3 means blob
//            }
//        }
//    }
}

public extension Repository {
    func diffTreeToTree(oldTree: Tree?, newTree: Tree?, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
        var diff: OpaquePointer?
        let result = git_diff_tree_to_tree(&diff, pointer, oldTree?.pointer, newTree?.pointer, &options.diff_options)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_tree"))
        }

        return .success(Diff(diff!))
    }

    func diffTreeToIndex(tree: Tree, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
        var diff: OpaquePointer?
        let result = git_diff_tree_to_index(&diff, pointer, tree.pointer, nil /* index */, &options.diff_options)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_index"))
        }

        return .success(Diff(diff!))
    }
    
    func diffTreeToWorkdir(tree: Tree, options: DiffOptions = DiffOptions()) -> Result<Diff, Error> {
        var diff: OpaquePointer?
        
        let result = options.with_diff_options { options in
            git_diff_tree_to_workdir(&diff, pointer, tree.pointer, &options)
        }

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_diff_tree_to_workdir"))
        }

        return .success(Diff(diff!))
    }
    
    
}
