//
//  OID.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 11/17/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

/// An identifier for a Git object.
public struct OID {
    public let oid: git_oid
    /// Create an instance from a libgit2 `git_oid`.
    public init(_ oid: git_oid) {
        self.oid = oid
    }
    
    public static func create(from string: String) -> Result<OID, Error> {
        if string.lengthOfBytes(using: String.Encoding.ascii) > 40 {
            return .failure(WTF("string length > 40"))
        }
        
        var oid = git_oid()
        
        return git_try("git_oid_fromstr") { git_oid_fromstr(&oid, string) }
            .map { OID(oid) }
    }
    
    // TODO: result
    public init?(string: String) {
        // libgit2 doesn't enforce a maximum length
        if string.lengthOfBytes(using: String.Encoding.ascii) > 40 {
            return nil
        }
        
        let pointer = UnsafeMutablePointer<git_oid>.allocate(capacity: 1)
        let result = git_oid_fromstr(pointer, string)
        
        if result < GIT_OK.rawValue {
            pointer.deallocate()
            return nil
        }
        
        oid = pointer.pointee
        pointer.deallocate()
    }
}

extension OID: CustomStringConvertible {
    public var description: String {
        var oidInternal = self.oid
        return git_oid_tostr_s(&oidInternal)?.asString() ?? "failed to get oid description"
    }
}

public extension OID {
    var oidShort: String { String("\( self )".prefix(7)) }
    var oidLong: String  { String("\( self )") }
}

extension OID: Hashable {
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: oid.id) {
            hasher.combine(bytes: $0)
        }
    }
    
    public static func == (lhs: OID, rhs: OID) -> Bool {
        var left = lhs.oid
        var right = rhs.oid
        return git_oid_cmp(&left, &right) == 0
    }
}
