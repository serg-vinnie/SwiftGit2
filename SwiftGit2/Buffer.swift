//
//  File.swift
//  SwiftGit2-OSX
//
//  Created by Serhii Vynnychenko on 2/10/20.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public final class Buffer {
	let pointer : UnsafeMutablePointer<git_buf>
	
	public var isBinary 	: Bool { 1 == git_buf_is_binary(pointer) }
	public var containsNul 	: Bool { 1 == git_buf_contains_nul(pointer) }
	
	
	public init(pointer: UnsafeMutablePointer<git_buf>) {
		self.pointer = pointer
	}
	
	deinit {
		dispose()
		pointer.deallocate()
	}
	
	public func asString() -> String? {
		guard !isBinary else { return nil }
		
		let data = Data(bytesNoCopy: pointer.pointee.ptr, count: pointer.pointee.size, deallocator: .none)
		return String(data: data, encoding: .utf8)
	}
	
	public func dispose() {
		git_buf_dispose(pointer)
	}
	// 
}
