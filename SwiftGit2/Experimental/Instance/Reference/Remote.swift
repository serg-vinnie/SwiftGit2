//
//  RemoteRepo.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Remote : InstanceProtocol {
	public let pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_remote_free(pointer)
	}
}

public extension Remote {	
	/// The name of the remote repo
	public var name: String { String(validatingUTF8: git_remote_name(pointer))! }
	
	/// The URL of the remote repo
	///
	/// This may be an SSH URL, which isn't representable using `NSURL`.
	
	//TODO:LAME HACK
	public var URL: String {
		let url = String(validatingUTF8: git_remote_url(pointer))!
		
		return urlGetHttp(url: url)
	}
	
	// https://github.com/ukushu/PushTest.git
	// ssh://git@github.com:ukushu/PushTest.git
	private func urlGetHttp(url: String) -> String {
		var url = String(validatingUTF8: git_remote_url(pointer))!

		if url.contains("https://") {
			return url
		}

		//else this is ssh and need to make https

		if url.contains("@") {
			let tmp = url.split(separator: "@")
			if tmp.count == 2 { url = String(tmp[1]) }
		}

		url = url.replacingOccurrences(of: "ssh://", with: "")
				.replacingOccurrences(of: ":", with: "/")

		return "https://\(url)"
	}

	// https://github.com/ukushu/PushTest.git
	// ssh://git@github.com:ukushu/PushTest.git
	private func urlGetSsh(url: String) -> String {
		var newUrl = url

		if newUrl.contains("github") {
			if !newUrl.contains("ssh://") && newUrl.contains("git@") {
				newUrl = "ssh://\(url)"
			}
			else if newUrl.contains("ssh://") && !newUrl.contains("git@") {
				newUrl = url.replacingOccurrences(of: "ssh://", with: "ssh://git@")
			}
		}
		else{
			if !newUrl.contains("ssh://"){
				newUrl = "ssh://\(url)"
			}
		}

		return newUrl.replacingOccurrences(of: ":", with: "/")
	}
	
	/// Download new data and update tips
	/// Input:  REMOTE (like an "Origin")
	public func fetch(options: FetchOptions) -> Result<(), NSError> {
		var opts = options.fetch_options
		
		//let resultInit = git_fetch_init_options(&opts, UInt32(GIT_FETCH_OPTIONS_VERSION))
		//assert(resultInit == GIT_OK.rawValue)
		
		return _result((), pointOfFailure: "git_remote_fetch") {
			git_remote_fetch(pointer, nil, &opts, nil)
		}
	}
}


public class FetchOptions {
	private(set) var fetch_options : git_fetch_options
	let credentials: Credentials_OLD
	
	public init(credentials: Credentials_OLD) {
		self.credentials = credentials
		self.fetch_options = git_fetch_options()
		
		let result = git_fetch_options_init(&fetch_options, UInt32(GIT_FETCH_OPTIONS_VERSION))
		assert(result == GIT_OK.rawValue)
		
		fetch_options.callbacks.payload = self.credentials.toPointer()
		fetch_options.callbacks.credentials = credentialsCallback

		
	}
}