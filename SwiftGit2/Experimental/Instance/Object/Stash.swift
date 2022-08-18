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



public struct StashFlags: OptionSet {
    public var rawValue: UInt32
    public init(rawValue: UInt32){
        self.rawValue = rawValue
    }
    
    public static let defaultt = StashFlags(rawValue: GIT_STASH_DEFAULT.rawValue)
    public static let keepIndex = StashFlags(rawValue: GIT_STASH_KEEP_INDEX.rawValue)
    public static let includeUntracked = StashFlags(rawValue: GIT_STASH_INCLUDE_UNTRACKED.rawValue)
    public static let includeIgnored = StashFlags(rawValue: GIT_STASH_INCLUDE_IGNORED.rawValue)
}

public struct Stash {
    public let message: String?
    public let index: Int
    public let id: OID?
    public var commitOIDofStash: OID? { id }
}

extension Stash: Identifiable { }

extension Stash: Hashable { }

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
        
        let sth = Stash(message: msg, index: index, id: (id?.pointee)?.asOID() )
        
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
