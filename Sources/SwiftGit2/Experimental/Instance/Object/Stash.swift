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
    
    nonisolated(unsafe) public static let defaultt          = StashFlags(rawValue: GIT_STASH_DEFAULT.rawValue)
    nonisolated(unsafe) public static let keepIndex         = StashFlags(rawValue: GIT_STASH_KEEP_INDEX.rawValue)
    nonisolated(unsafe) public static let includeUntracked  = StashFlags(rawValue: GIT_STASH_INCLUDE_UNTRACKED.rawValue)
    nonisolated(unsafe) public static let includeIgnored    = StashFlags(rawValue: GIT_STASH_INCLUDE_IGNORED.rawValue)
}

public struct Stash {
    public let message: String
    public let index: Int
    public let oid: OID
    public let time: Date
}

extension Stash: Identifiable {
    public var id: OID { oid }
}

extension Stash: Hashable { }

//////////////////////////////////
///HELPERS
////////////////////////////////

public class StashCallbacks {
    let repo : Repository
    var stashes: [Stash] = []
    
    init(repo: Repository) {
        self.repo = repo
    }
    
    let git_stash_cb: git_stash_cb = { index, message, id, payload in
        let me = payload.unsafelyUnwrapped
            .bindMemory(to: StashCallbacks.self, capacity: 1)
            .pointee
        
        let msg: String?
        
        if let msgCCchar = message {
            msg = String(cString:msgCCchar)
        } else {
            msg = nil
        }
        
        let oid = (id?.pointee)?.asOID()
        
        if let msg = msg, let oid = oid, let time = me.date(oid: oid).maybeSuccess {
            let sth = Stash(message: msg, index: index, oid: oid, time: time)
            
            me.stashes.append( sth )
        }
        
        return 0
    }
    
    func date(oid: OID?) -> R<Date> {
        oid.asNonOptional | { repo.commit(oid: $0) } | { $0.time }
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
