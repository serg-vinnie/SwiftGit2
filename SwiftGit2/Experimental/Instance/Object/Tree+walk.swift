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

public extension TreeID {
    func subTree(name: String) -> R<TreeID> {
        self.tree | { $0.subTree(name: name) } | { TreeID(repoID: repoID, oid: $0) }
    }
    
    func blob(name: String) -> R<BlobID> { // NOT PATH
        self.tree | { $0.blob(name: name) } | { BlobID(repoID: repoID, oid: $0) }
    }
}

public extension Tree {
//    var treeID: TreeID { TreeID(repoID: <#T##RepoID#>, oid: <#T##OID#>) }
    
    func entries(repoID: RepoID) -> [TreeID.Entry] {
        (0..<self.count).compactMap { self.entry(idx: $0) }.map { $0.dbEntry(treeID: TreeID(repoID: repoID, oid: $0.oid)) }
    }
    
    func iteratorEntries(repoID: RepoID, url: URL) -> [TreeID.IteratorEntry] {
        (0..<self.count).compactMap { self.entry(idx: $0) }
            .map { TreeID.IteratorEntry(treeID: TreeID(repoID: repoID, oid: self.oid), url: url, oid: $0.oid, name: $0.name) }
    }
    
    fileprivate func blob(name: String) -> R<OID> {
        for idx in 0..<count {
            guard let entry = entry(idx: idx) else { break }
            guard entry.type == GIT_OBJECT_BLOB else { continue }
            if entry.name == name {
                return .success(entry.oid)
            }
        }
        return .wtf("[Tree \(self.oid.oidShort)] blob not found : \(name) ")
    }
    
    fileprivate func subTree(name: String) -> R<OID> {
        for idx in 0..<count {
            guard let entry = entry(idx: idx) else { break }
            guard entry.type == GIT_OBJECT_TREE else { continue }
            if entry.name == name {
                return .success(entry.oid)
            }
        }
        return .wtf("subTree not found : \(name)")
    }
    
    private func entry(idx: Int) -> TreeEntryNoFree? {
        if let p = git_tree_entry_byindex(self.pointer, idx) {
            return TreeEntryNoFree(p)
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
    let entry = TreeEntryNoFree(_p)
    let root = root.flatMap(String.init(validatingUTF8:)) ?? "WTF"
    let _payload = GitTreePayload.unretained(pointer: payload)
    
    _payload.oids.append(entry.oid)
    print("root: \(root), entry: \(entry.oid.oidShort) \(entry.name)" )
    
    return 0
}

fileprivate class TreeEntryNoFree : TreeEntryProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
}

protocol TreeEntryProtocol {
    var pointer: OpaquePointer { get }
}

extension TreeEntryProtocol {
    var name : String { git_tree_entry_name(self.pointer).asSwiftString }
    var oid  : OID { OID(git_tree_entry_id(self.pointer).pointee) }
    var type : git_object_t { git_tree_entry_type(self.pointer) }
    
    func dbEntry(treeID: TreeID) -> TreeID.Entry {
        if type == GIT_OBJECT_BLOB {
            return TreeID.Entry(treeID: treeID, name: name, oid: oid, kind: .blob)
        } else if type == GIT_OBJECT_TREE {
            return TreeID.Entry(treeID: treeID, name: name, oid: oid, kind: .tree)
        } else {
            return TreeID.Entry(treeID: treeID, name: name, oid: oid, kind: .submodule)
        }
    }
    
    func dbEntry(treeID: TreeID, path: String, commitID: CommitID?) -> GitTreeEntry {
        let repoID = treeID.repoID
        
        if type == GIT_OBJECT_BLOB {
            let blobID = BlobID(repoID: repoID, oid: oid)
            let filePath = path.appendingPath(component: name)
            let fileID = GitFileID(path: filePath, blobID: blobID, commitID: commitID)
            return .file( fileID )
            
        } else if type == GIT_OBJECT_TREE {
            return .tree( TreeID(repoID: repoID, oid: self.oid))
            
        } else {
            // TODO: proper submodule handling
            let subID = SubmoduleID(repoID: treeID.repoID, name: name)
            return .submodule(subID)
        }
    }
}
