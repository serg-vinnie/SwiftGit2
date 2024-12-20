//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Branch
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public enum BranchLocation {
    case local
    case remote
}

public protocol Branch: InstanceProtocol {
    var nameAsBranch: String? { get }
    var nameAsReference: String { get }
    var nameAsReferenceCleaned: String { get }
    var isBranch: Bool { get }
    var isRemote: Bool { get }

    var target : OID? { get }
    var target_resut : R<OID> { get }

    func set(target: OID, message: String) -> Result<Reference, Error>
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Reference
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Branch {
    var nameAsBranch: String? { try? branchName.get() }
}

public extension Branch {
    /// can be called only for local branch;
    func upstreamName(clean: Bool = false) -> Result<String, Error> {
        if clean {
            return upstream().map { $0.nameAsReference.replace(of: "refs/remotes/", to: "") }
        }

        return upstream().map { $0.nameAsReference }
    }

    /// Can be used only on local branch
    func upstream() -> Result<Reference, Error> {
        git_instance(of: Reference.self, "git_branch_upstream") { pointer in
            git_branch_upstream(&pointer, self.pointer)
        }
    }

    /// can be called only for local branch;
    ///
    /// newNameWithPath MUST BE WITH "refs/heads/"
    /// Will reset assigned upstream Name
    func setLocalName(newNameWithPath: String) -> Result<Branch, Error> {
        guard newNameWithPath.contains("refs/heads/")
        else { return .failure(BranchError.NameIsNotLocal as Error) }

        return (self as! Reference).rename(.full(newNameWithPath)).flatMap { $0.asBranch() }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// High Level code

// Low Level code
public extension Repository {
    func branches(_ location: BranchLocation) -> Result<[Branch], Error> {
        switch location {
        case .local:
            return references(withPrefix: "refs/heads/")
                .flatMap { $0.flatMap { $0.asBranch() } }
        
        case .remote:
            return references(withPrefix: "refs/remotes/")
                .flatMap { $0.flatMap { $0.asBranch() } }
        }
    }
    
    /// Get upstream name by branchName
    func upstreamName(branchName: String) -> Result<String, Error> {
        var buf = git_buf(ptr: nil, asize: 0, size: 0)
        
        return _result({ Buffer(buf: buf) }, pointOfFailure: "") {
            branchName.withCString { refname in
                git_branch_upstream_name(&buf, self.pointer, refname)
            }
        }
        .flatMap { $0.asString() }
    }
}

private extension Branch {
    private var branchName: Result<String, Error> {
        var pointer: UnsafePointer<Int8>? // Pointer to the abbreviated reference name. Owned by ref, do not free.
        
        return git_try("git_branch_name") {
            git_branch_name(&pointer, self.pointer)
        }
        .flatMap { String.validatingUTF8(cString: pointer!) }
    }
}

////////////////////////////////////////////////////////////////////
/// ERRORS
////////////////////////////////////////////////////////////////////

enum BranchError: Error {
    // case BranchNameIncorrectFormat
    case NameIsNotLocal
    // case NameMustNotContainsRefsRemotes
}

extension BranchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        //	case .BranchNameIncorrectFormat:
        //	  return "Name must include 'refs' or 'home' block"
        case .NameIsNotLocal:
            return "Name must be Local. It must have include 'refs/heads/'"
            //	case .NameMustNotContainsRefsRemotes:
            //	  return "Name must be Remote. But it must not contain 'refs/remotes/'"
        }
    }
}
