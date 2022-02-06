//
//  TagNew.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 06.02.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

///////////////////////////////////////////
// Must be child or reference??? but it is not
///////////////////////////////////////////

/// An annotated git tag.
public struct Tag: InstanceProtocol, ObjectType, Hashable  {
    public var pointer: OpaquePointer
    public static let type = GIT_OBJECT_TAG
    
    /// The OID of the tag.
    public let oid: OID
    
    /// The tagged object.
    //public let target: Pointer
    
    /// The tagged object.
    public var targetOid: OID
    
    /// The name of the tag.
    public let name: String
    
    /// The tagger (author) of the tag.
    public let tagger: git_signature
    
    /// The message of the tag.
    public let message: String
    
    /// Create an instance with a libgit2 `git_tag`.
    public init(_ pointer: OpaquePointer) {
        self.pointer = pointer
        oid = OID(git_object_id(pointer).pointee)
        let targetOid = OID(git_tag_target_id(pointer).pointee)
        self.targetOid = targetOid
        //target = Pointer(oid: targetOid, type: git_tag_target_type(pointer))!
        name = String(validatingUTF8: git_tag_name(pointer))!
        tagger = git_tag_tagger(pointer).pointee
        message = String(validatingUTF8: git_tag_message(pointer))!
    }
}
