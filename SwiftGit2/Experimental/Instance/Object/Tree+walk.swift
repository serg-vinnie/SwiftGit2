//
//  Tree+walk.swift
//  SwiftGit2-OSX
//
//  Created by loki on 21.12.2023.
//  Copyright © 2023 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Tree {
    var entries : R<[String]> {
        let b = (0..<self.count).compactMap { self.entry(idx: $0) }
        
        return .notImplemented
    }
    
    private func entry(idx: Int) -> TreeEntry_? {
        if let p = git_tree_entry_byindex(self.pointer, idx) {
            return TreeEntry_(p)
        }
        return nil
    }
    
    func walk() -> R<Void> {
        let p = GitTreePayload()
        let _p = p.toRetainedPointer()
        defer {
            GitTreePayload.release(pointer: _p)
        }
        
        let r = git_try("git_tree_walk") {
            git_tree_walk(self.pointer, GIT_TREEWALK_PRE, treeCB, _p)
        } //.map { _ in () }
        
        return r
    }
    
}

fileprivate class GitTreePayload : GitPayload {
    var oids = [OID]()
}

func treeCB(_ root: UnsafePointer<Int8>?, _ tree_entry: OpaquePointer?, _ payload: UnsafeMutableRawPointer?) -> (Int32) {
    guard let _p = tree_entry else { return -1 }
    guard let payload = payload else { return -1 }
    let entry = TreeEntryWalk(_p)
    let root = root.flatMap(String.init(validatingUTF8:)) ?? "WTF"
    let _payload = GitTreePayload.unretained(pointer: payload)
    
    _payload.oids.append(entry.oid)
    print("root: \(root), entry: \(entry.oid.oidShort) \(entry.name)" )
    
    return 0
}

fileprivate class TreeEntry_ : TreeEntry{
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_tree_entry_free(self.pointer)
    }
}

fileprivate class TreeEntryWalk : TreeEntry{
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
}

protocol TreeEntry {
    var pointer: OpaquePointer { get }
}

extension TreeEntry {
    var name : String { git_tree_entry_name(self.pointer).asSwiftString }
//    var type : git_object_t { git_tree_entry_type(self.pointer) }
    var oid  : OID { OID(git_tree_entry_id(self.pointer).pointee) }
}
