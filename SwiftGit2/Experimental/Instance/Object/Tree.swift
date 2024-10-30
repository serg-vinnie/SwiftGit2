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




public extension Tree {
    var oid : OID { OID(git_tree_id(self.pointer).pointee) }
    var count : Int { git_tree_entrycount(self.pointer) }
}



public extension Tree {

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
    func diffTreeToTree(oldTree: Tree?, newTree: Tree?, options: DiffOptions = DiffOptions()) -> R<Diff> {
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
