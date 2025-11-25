//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

/// A git object.
public protocol ObjectType {
    static var type: git_object_t { get }

    /// The OID of the object.
    var oid: OID { get }

    /// Create an instance with the underlying libgit2 type.
    init(_ pointer: OpaquePointer)
}

public extension ObjectType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}
