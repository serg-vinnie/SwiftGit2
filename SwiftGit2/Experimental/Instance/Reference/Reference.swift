//
//  ReferenceInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

public class Reference: Branch { // Branch: InstanceProtocol
    public var pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_reference_free(pointer)
    }
}

public extension Reference {
    var nameAsReference: String { String(validatingUTF8: git_reference_name(pointer)) ?? "" }
    var nameAsReferenceSymbolic: String? { String(validatingUTF8: git_reference_symbolic_target(pointer)) }
    
    var nameAsReferenceCleaned: String{ nameAsReference.fixNameAsReference() }

    var isDirect: Bool { git_reference_type(pointer) == GIT_REFERENCE_DIRECT }
    var isSymbolic: Bool { git_reference_type(pointer) == GIT_REFERENCE_SYMBOLIC }

    var isTag: Bool { git_reference_is_tag(pointer) != 0 } // 1 when the reference lives in the refs/tags* namespace; 0 otherwise.
    var isBranch: Bool { git_reference_is_branch(pointer) != 0 } // 1 when the reference lives in the refs/heads namespace; 0 otherwise.
    var isRemote: Bool { git_reference_is_remote(pointer) != 0 } // 1 when the reference lives in the refs/remotes namespace; 0 otherwise.

    func asBranch() -> Result<Branch, Error> {
        if isBranch || isRemote {
            return .success(self as Branch)
        }
        return .failure(WTF("asBranch() failed for \(nameAsReference)"))
    }

    @available(*, deprecated, message: "use asBranch() instead")
    var asBranch_: Branch? {
        if isBranch || isRemote {
            return self as Branch
        }
        return nil
    }
    
    @available(*, deprecated, message: "prefered to use Duo<Reference,Repository> instead if possible")
    var targetOID: Result<OID, Error> { targetOIDNoWarning }
    
    var targetOIDNoWarning: Result<OID, Error> {
        if isSymbolic {
//            var resolved: OpaquePointer?
//            defer {
//                git_reference_free(resolved)
//            }
            
            return .wtf("Mail to support@taogit.com: targetOIDNoWarning used in wrong way")
            
//            git_try("git_reference_name_to_id")
//                { git_reference_resolve(&resolved, self.pointer) }
//                .map { OID(git_reference_target(resolved).pointee) }
            
        } else {
            return .success(OID(git_reference_target(pointer).pointee))
        }
    }
}

public extension Repository {
    var references : R<[String]> {
        var strarray = git_strarray()
        defer {
            git_strarray_free(&strarray) // free results of the git_reference_list call
        }
        return git_try("git_reference_list") {
            git_reference_list(&strarray, self.pointer)
        }
        .map { strarray.map { $0 } }
    }
    
    func references(withPrefix prefix: String) -> Result<[Reference], Error> {
        var strarray = git_strarray()
        defer {
            git_strarray_free(&strarray) // free results of the git_reference_list call
        }
        
        return git_try("git_reference_list") {
            git_reference_list(&strarray, self.pointer)
        }
        .map { strarray.filter { $0.hasPrefix(prefix) } }
        .flatMap { $0.flatMap { self.reference(name: $0) } }
    }
    
    func reference(name: String) -> Result<Reference, Error> {
        var pointer: OpaquePointer?
        
        return _result({ Reference(pointer!) }, pointOfFailure: "git_reference_lookup") {
            git_reference_lookup(&pointer, self.pointer, name)
        }
    }
}

fileprivate extension Repository {
    func referenceTarget(name: String) -> R<OID> {
        var oid = git_oid() // out
        
        return git_try("git_reference_name_to_id") {
                name.withCString { name in
                    git_reference_name_to_id(&oid, self.pointer, name)
                }
            }
            .map {
                OID(oid)
            }
    }
}

public extension Reference {
    func with(_ repo: Repository) -> Duo<Reference, Repository> {
        return Duo(self, repo)
    }
}


public extension Duo where T1 == Reference, T2 == Repository {
    func targetOID() -> R<OID> {
        let (ref, repo) = value
        
        if ref.isSymbolic {
            return ref.nameAsReferenceSymbolic.asNonOptional | { repo.referenceTarget(name: $0) }
        } else {
            return ref.targetOIDNoWarning
        }
    }
    
    // Getting oid for Advanced or LightWeight tag
    func getTagOid() -> R<OID> {
        let repo = value.1
        
        return self.targetOID()
            .flatMap { oid -> R<OID> in
                if repo.commitExist(oid: oid) {
                    // this is lightWeight Tag
                    return .success(oid)
                } else {
                    // this is Advanced Tag
                    return repo.tagLookup(oid: oid).map{ $0.targetOid }
                }
            }
    }
}


/////////////////////////
/// HELPERS
/////////////////////////

fileprivate extension String {
    func fixNameAsReference() -> String {
        self.split(separator: "/").dropFirst(2).joined(separator:"/")
    }
}

fileprivate extension Repository {
    func commitExist(oid: OID) -> Bool {
        var oidInternal = oid.oid
        var resPointer: OpaquePointer?
        
        git_commit_lookup(&resPointer, self.pointer, &oidInternal)
        
        if let _ = resPointer {
            return true
        }
        
        return false
    }
}
