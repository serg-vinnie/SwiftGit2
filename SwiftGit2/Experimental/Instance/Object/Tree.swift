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
        git_instance(of: Diff.self, "git_diff_tree_to_tree") { diff in
            options.with_diff_options { options in
                git_diff_tree_to_tree(&diff, pointer, oldTree?.pointer, newTree?.pointer, &options)
            }
        }
    }

    func diffTreeToIndex(tree: Tree, options: DiffOptions = DiffOptions()) -> R<Diff> {
        git_instance(of: Diff.self, "git_diff_tree_to_index") { diff in
            options.with_diff_options { options in
                git_diff_tree_to_index(&diff, pointer, tree.pointer, nil /* index */, &options)
            }
        }
    }
    
    func diffTreeToWorkdir(tree: Tree, options: DiffOptions = DiffOptions()) -> R<Diff> {
        git_instance(of: Diff.self, "git_diff_tree_to_workdir") { diff in
            options.with_diff_options { options in
                git_diff_tree_to_workdir(&diff, pointer, tree.pointer, &options)
            }
        }
    }
    
    
}
