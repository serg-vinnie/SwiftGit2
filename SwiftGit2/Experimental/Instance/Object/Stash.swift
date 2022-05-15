//
//  Stash.swift
//  SwiftGit2Tests
//
//  Created by UKS on 15.05.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import CoreMIDI

public extension Repository {
    func stashForeach() -> R<[Stash]> {
        var cb = StashCallbacks()
        
        return _result( { cb.stashes } , pointOfFailure: "git_stash_foreach") {
            git_stash_foreach(self.pointer, cb.git_stash_cb, &cb)
        }
    }
}

public struct StashFlags: OptionSet {
    public let rawValue: UInt32
    public init(rawValue: UInt32){
        self.rawValue = rawValue
    }
    
    public static let defaultt = StashFlags(rawValue: GIT_STASH_DEFAULT.rawValue)
    public static let keepIndex = StashFlags(rawValue: GIT_STASH_KEEP_INDEX.rawValue)
    public static let includeUntracked = StashFlags(rawValue: GIT_STASH_INCLUDE_UNTRACKED.rawValue)
    public static let includeIgnored = StashFlags(rawValue: GIT_STASH_INCLUDE_IGNORED.rawValue)
}

public class StashCallbacks_ {
    
    let git_stash_cb : git_stash_cb = { index, message, id, payload   in
//        callbacks.unsafelyUnwrapped
//            .bindMemory(to: StashCallbacks.self, capacity: 1)
//            .pointee
//            .file(delta: Diff.Delta(delta.unsafelyUnwrapped.pointee), progress: progress)
        
        return 0
    }
}

public struct Stash {
    let message: String?
    let id: OID?
    var commitOIDofStash: OID? { id }
}



//////////////////////////////////
///HELPERS
////////////////////////////////

public class StashCallbacks {
    var stashes: [Stash] = []
    
    let git_stash_cb: git_stash_cb = { index, message, id, payload in
        let stashCallbacksInstance = payload.unsafelyUnwrapped
            .bindMemory(to: StashCallbacks.self, capacity: 1)
            .pointee
        
        let msg: String?
        
        if let msgCCchar = message
            { msg = String(cString:msgCCchar) }
            else { msg = nil }
        
        let sth = Stash(message: msg, id: (id?.pointee)?.asOID() )
        
        stashCallbacksInstance.stashes.append( sth )
        
        return 0
    }
}

public extension git_oid {
    func asOID() -> OID {
        OID(self)
    }
}

public extension Optional where Wrapped == git_oid {
    func asOID() -> OID? {
        self?.asOID() ?? nil
    }
}
