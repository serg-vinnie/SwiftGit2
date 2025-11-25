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

public typealias GitIndexerProgress = git_indexer_progress
public typealias TransferProgressCB = (GitIndexerProgress) -> (Bool) // return false to cancel progree

public extension GitIndexerProgress {
    var ratio : CGFloat {
        CGFloat(indexed_objects)/CGFloat(total_objects)
    }
}

public class MutexRecursiveLock  {
    private var _lock = pthread_mutex_t()
    
    init() {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
        pthread_mutex_init(&_lock, &attr)
    }
    
    deinit {
        pthread_mutex_destroy(&_lock)
    }
    
    @inline(__always) public func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        pthread_mutex_lock(&_lock)
        defer { pthread_mutex_unlock(&_lock) }
        return try f()
    }
}


fileprivate final class CallbacksLock {
    private var _lock = pthread_mutex_t()

    init() {
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
        pthread_mutex_init(&_lock, &attr)
    }
    
    deinit {
        pthread_mutex_destroy(&_lock)
    }
    
    fileprivate func lock() {
        pthread_mutex_lock(&_lock)
    }
    
    fileprivate func unlock() {
        pthread_mutex_unlock(&_lock)
    }
}

nonisolated(unsafe) fileprivate let callbackLock = CallbacksLock()

fileprivate final class SSHAccessLock {
    init() {
        print("SSHAccessLock+ " + Thread.current.dbgName)
        callbackLock.lock()
    }
    deinit {
        print("SSHAccessLock- " + Thread.current.dbgName)
        callbackLock.unlock()
    }
}

public class RemoteCallbacks: GitPayload {
    fileprivate var locker : SSHAccessLock?
    fileprivate func lock() { if locker == nil { locker = .init() } }
    fileprivate func unlock() { locker = nil }
    
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
            if case .function(let block) = cred {
                switch block() {
                case .success(let cred): return cred
                case .failure(_): return .default
                }
            }
            
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

//let connectionLocking = UnfairLock()

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

//        return connectionLocking.locked {
        return body(&remote_callbacks)
//        }
    }
}

/// Handle the request of credentials, passing through to a wrapped block after converting the arguments.
/// Converts the result to the correct error code required by libgit2 (0 = success, 1 = rejected setting creds,
/// -1 = error)
func credentialsCallback(
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
        _payload.lock()
        result = git_credential_ssh_key_from_agent(cred, name!)
    case let .plaintext(username, password):
        result = git_credential_userpass_plaintext_new(cred, username, password)
    case let .sshMemory(username, publicKey, privateKey, passphrase):
        _payload.lock()
        result = git_credential_ssh_key_memory_new(cred, username, publicKey, privateKey, passphrase)
    case let .ssh(publicKey: publicKey, privateKey: privateKey, passphrase: passphrase):
        _payload.lock()
        result = git_credential_ssh_key_new(cred, name, publicKey, privateKey, passphrase)
    case let .function(block):
        return -1 // this block should be handled already
    }

    return (result != GIT_OK.rawValue) ? -1 : 0
}

// Return a value less than zero to cancel process
private func transferCallback(stats: UnsafePointer<GitIndexerProgress>?, payload: UnsafeMutableRawPointer?) -> Int32 {
    guard let stats = stats?.pointee else { return -1 }
    guard let payload = payload else { return -1 }

    let callbacks = RemoteCallbacks.unretained(pointer: payload)
    
    callbacks.unlock()

    // if progress callback didn't set just continue
    if let transferProgress = callbacks.transferProgress {
        if transferProgress(stats) == false {
            return -1 // if callback returns false return -1 to cancel transfer
        }
    }

    return 0
}
