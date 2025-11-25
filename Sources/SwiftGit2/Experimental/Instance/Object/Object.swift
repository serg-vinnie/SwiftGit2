//
//  ObjectInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public protocol Object: InstanceProtocol {}

public extension Object {
    var oid: OID { OID(git_object_id(pointer).pointee) }
    
    var oidShort: String { self.oid.oidShort }
}

public extension Repository {
    func commit(oid: OID) -> Result<Commit, Error> {
        return instanciate(oid)
    }
    
    func instanciate<ObjectType>(_ oid: OID) -> Result<ObjectType, Error> where ObjectType: Object {
        var pointer: OpaquePointer?
        var oid = oid.oid
        
        return git_try("git_object_lookup") {
            git_object_lookup(&pointer, self.pointer, &oid, gitType(for: ObjectType.self))
        }
        .map { ObjectType(pointer!) }
    }
    
    private func gitType<ObjectType>(for type: ObjectType.Type) -> git_object_t where ObjectType: Object {
        switch type {
        case is Commit.Type: return GIT_OBJECT_COMMIT
        case is Tree.Type: return GIT_OBJECT_TREE
        case is Blob.Type: return GIT_OBJECT_BLOB
        case is Tag.Type: return GIT_OBJECT_TAG
            
        default: return GIT_OBJECT_ANY
        }
    }
}
