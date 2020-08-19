//
//  BranchInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Branch
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public enum BranchLocation {
	case local
	case remote
}

public protocol Branch: InstanceProtocol {
	var shortName	: String	{ get }
	var name		: String	{ get }
	var commitOID	: OID?		{ get }
}

public extension Branch {
	var isBranch : Bool { git_reference_is_branch(pointer) != 0 }
	var isRemote : Bool { git_reference_is_remote(pointer) != 0 }

	var isLocalBranch	: Bool { self.name.starts(with: "refs/heads/") }
	var isRemoteBranch	: Bool { self.name.starts(with: "refs/remotes/") }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Reference
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extension Reference : Branch {}
	
extension Branch {
	public var shortName 		: String 	{ getName() }
	public var name 	: String 	{ getLongName() }
	public var commitOID	: OID? 		{ getCommitOID() }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Repository
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Repository {
	func branchTest()  -> Result<Branch, NSError> {
		return reference(name: "").map{ $0.asBranch! }
	}
	
	func branches( _ location: BranchLocation) -> Result<[Branch], NSError> {
		switch location {
		case .local:		return references(withPrefix: "refs/heads/")
										.map { $0.compactMap { $0.asBranch } }
		case .remote: 		return references(withPrefix: "refs/remotes/")
										.map { $0.compactMap { $0.asBranch } }
		}
	}
	
	func upstreamName(branchLongName: String) -> Result<String, NSError> {
		let buf_ptr = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		buf_ptr.pointee.asize = 0
		buf_ptr.pointee.size = 0
		buf_ptr.pointee.ptr = nil
		
		return _result({Buffer(pointer: buf_ptr)}, pointOfFailure: "" ) {
			branchLongName.withCString { refname in
				git_branch_upstream_name(buf_ptr, self.pointer, refname)
			}
		}.map { $0.asString() ?? "" }
	}
}

private extension Branch {
	func getName() -> String {
		var namePointer: UnsafePointer<Int8>? = nil
		let success = git_branch_name(&namePointer, pointer)
		guard success == GIT_OK.rawValue else {
			return ""
		}
		return String(validatingUTF8: namePointer!) ?? ""
	}
	
	func getLongName() -> String {
		return String(validatingUTF8: git_reference_name(pointer)) ?? ""
	}
	
	func getCommitOID() -> OID? {
		if git_reference_type(pointer).rawValue == GIT_REFERENCE_SYMBOLIC.rawValue {
			var resolved: OpaquePointer? = nil
			defer {
				git_reference_free(resolved)
			}
			
			let success = git_reference_resolve(&resolved, pointer)
			guard success == GIT_OK.rawValue else {
				return nil
			}
			return OID(git_reference_target(resolved).pointee)
			
		} else {
			return OID(git_reference_target(pointer).pointee)
		}
	}
}
