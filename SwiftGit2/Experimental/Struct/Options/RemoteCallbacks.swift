//
//  RemoteCallbacks.swift
//  SwiftGit2-OSX
//
//  Created by loki on 25.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public typealias TransferProgressCB = (git_indexer_progress) -> (Bool) // return false to cancel progree

public class RemoteCallbacks: GitPayload {
    var list = [Credentials]()
    var callback : AuthCB?
    
    var recentCredentials = Credentials.default
    private var remote_callbacks = git_remote_callbacks()
    public var transferProgress: TransferProgressCB?
    public var onStart : ()->() = { }
    public var onStop  : ()->() = { }

    public init(auth: Auth, transfer: TransferProgressCB? = nil) {
        self.transferProgress = transfer
        switch auth {
        case .match(let callback):
            self.callback = callback
        case .credentials(let cred):
            self.list = [cred]
        case .list(let list):
            self.list = Array(list.reversed()) // reversed to use popLast
        }

        let result = git_remote_init_callbacks(&remote_callbacks, UInt32(GIT_REMOTE_CALLBACKS_VERSION))
        assert(result == GIT_OK.rawValue)
    }
    
    func next(url: String?, username: String?) -> Credentials {
        if let cred = list.popLast() {
            return cred
        } else if let cb = callback {
            return cb(url, username)
        }
        
        return .none
    }

    #if DEBUG
        deinit {
            // print("RemoteCallbacks deinit")
        }
    #endif
}

let connectionLocking = UnfairLock()

extension RemoteCallbacks {
    func with_git_remote_callbacks<T>(_ body: (inout git_remote_callbacks) -> T) -> T {
        remote_callbacks.payload = toRetainedPointer()

        remote_callbacks.credentials = credentialsCallback
        remote_callbacks.transfer_progress = transferCallback

        onStart()
        defer {
            onStop()
            RemoteCallbacks.release(pointer: remote_callbacks.payload)
        }

        return connectionLocking.locked {
            body(&remote_callbacks)
        }
    }
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
private func credentialsCallback(
    cred: UnsafeMutablePointer<UnsafeMutablePointer<git_cred>?>?,
    url: UnsafePointer<CChar>?,
    username: UnsafePointer<CChar>?,
    _: UInt32,
    payload: UnsafeMutableRawPointer?
) -> Int32 {
    guard let payload = payload else { return -1 }

    let url = url.map(String.init(cString:))
    let name = username.map(String.init(cString:))

    let result: Int32
    
    let _payload = RemoteCallbacks.unretained(pointer: payload)
    _payload.recentCredentials = _payload.next(url: url, username: name)

    switch _payload.recentCredentials {
    case .none:
        return 1    // will fail with: [git_remote_connect]: remote authentication required but no callback set
    case .default:
        result = git_credential_default_new(cred)
    case .sshAgent:
        result = git_credential_ssh_key_from_agent(cred, name!)
    case let .plaintext(username, password):
        result = git_credential_userpass_plaintext_new(cred, username, password)
    case let .sshMemory(username, publicKey, privateKey, passphrase):
        result = git_credential_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
    case let .ssh(publicKey: publicKey, privateKey: privateKey, passphrase: passphrase):
        result = git_credential_ssh_key_new(cred, name, publicKey, privateKey, passphrase)
    }

    return (result != GIT_OK.rawValue) ? -1 : 0
}

// Return a value less than zero to cancel process
private func transferCallback(stats: UnsafePointer<git_indexer_progress>?, payload: UnsafeMutableRawPointer?) -> Int32 {
    guard let stats = stats?.pointee else { return -1 }
    guard let payload = payload else { return -1 }

    let callbacks = RemoteCallbacks.unretained(pointer: payload)

    // if progress callback didn't set just continue
    if let transferProgress = callbacks.transferProgress {
        if transferProgress(stats) == false {
            return -1 // if callback returns false return -1 to cancel transfer
        }
    }

    return 0
}
