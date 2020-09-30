//
//  Credentials.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 29.09.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

private class Wrapper<T> {
	let value: T

	init(_ value: T) {
		self.value = value
	}
}

public enum Credentials {
	case `default`
	case sshAgent
	case plaintext(username: String, password: String)
	case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)

	internal static func fromPointer(_ pointer: UnsafeMutableRawPointer) -> Credentials {
		return Unmanaged<Wrapper<Credentials>>.fromOpaque(UnsafeRawPointer(pointer)).takeRetainedValue().value
	}

	internal func toPointer() -> UnsafeMutableRawPointer {
		return Unmanaged.passRetained(Wrapper(self)).toOpaque()
	}
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
internal func credentialsCallback(
	cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>?>?,
	url: UnsafePointer<CChar>?,
	username: UnsafePointer<CChar>?,
	_: UInt32,
	payload: UnsafeMutableRawPointer? ) -> Int32 {

	let result: Int32

	// Find username_from_url
	let name = username.map(String.init(cString:))

	switch Credentials.fromPointer(payload!) {
	case .default:
		result = git_cred_default_new(cred)
	case .sshAgent:
		result = git_cred_ssh_key_from_agent(cred, name!)
	case .plaintext(let username, let password):
		result = git_cred_userpass_plaintext_new(cred, username, password)
	case .sshMemory(let username, let publicKey, let privateKey, let passphrase):
		result = git_cred_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
	}

	return (result != GIT_OK.rawValue) ? -1 : 0
}





public func CredGenerate(username: String = "git", passphrase: String = "") -> Result<CredentialSsh, NSError> {
	let sshMan = SshKeysManager()
	
	var pointer: UnsafeMutablePointer<git_credential>? = UnsafeMutablePointer<git_credential>.allocate(capacity: 1)
	
	
	
	return _result({ CredentialSsh(pointer: pointer) }, pointOfFailure: "git_cred_ssh_key_new") {
		git_cred_ssh_key_new(&pointer, username, sshMan.urlPublicKey.path, sshMan.urlPrivateKey.path, passphrase)
	}
	
//	func toPointer() -> UnsafeMutableRawPointer<git_credential>? {
//		
//	}
}

func getCredential(pointer: UnsafeMutablePointer<git_credential>?) -> Credentials {
	return Unmanaged<Wrapper<Credentials>>.fromOpaque(UnsafeRawPointer(pointer!)).takeRetainedValue().value
}


public class CredentialSsh {
	private(set) var pointer: UnsafeMutablePointer<git_credential>? = UnsafeMutablePointer<git_credential>.allocate(capacity: 1)

	public required init(pointer: UnsafeMutablePointer<git_credential>?) {
		self.pointer = pointer
	}

	deinit {
		git_credential_free(pointer)
		pointer!.deallocate()
	}
	
	public func toPointer() -> UnsafeMutableRawPointer {
		return UnsafeMutableRawPointer(pointer!)
	}
	
	public func toCallBack() -> git_credential_acquire_cb {
		
		//return (self.pointer, )
		
		return credCallback(url: "", username: "git") { $0.map(RemoteRepo.init) }
	}
	
	
	private func credCallback<A>(url urlOrig: String, username: String _ callback: (Result<OpaquePointer, NSError>) -> A) -> A {
		//var pointer: OpaquePointer? = nil
		let urlRepresentation = urlOrig
		var urlPointer = UnsafeMutablePointer<Int8>(mutating: (urlRepresentation as NSString).utf8String)
		
		let nameRepresentation = username
		var namePointer = UnsafeMutablePointer<Int8>(mutating: (nameRepresentation as NSString).utf8String)
		
		var allowTypes: UInt32 = 0
		
	

		let result = git_credential_acquire_cb(&pointer, urlPointer, namePointer, allowTypes, nil )
		
		//int git_credential_acquire_cb(git_credential **out, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload);
		
		guard result == GIT_OK.rawValue else {
			return callback(.failure(NSError(gitError: result, pointOfFailure: "git_credential_acquire_cb")))
		}

		return callback(.success(pointer!))
	}

}



