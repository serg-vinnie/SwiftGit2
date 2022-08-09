//
//  ReferenceID.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.07.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct ReferenceID : Equatable {
    public let repoID: RepoID
    public let name: String
    
    public init(repoID: RepoID, name: String) {
        self.repoID = repoID
        self.name = name
    }
}

public extension ReferenceID {
    var isBranch  : Bool { name.hasPrefix("refs/heads/") }
    var isRemote  : Bool { name.hasPrefix("refs/remotes/") }
    var isTag     : Bool { name.hasPrefix("refs/tags/") }
    
    var displayName : String {
        if isBranch {
            return name.replace(of: "refs/heads/", to: "")
        } else if let remote = remote {
            return name.replace(of: "refs/remotes/\(remote)/", to: "")
        } else if isTag {
            return name.replace(of: "refs/tags/", to: "")
        }
        
        assert(false)
        return name
    }
    
    var category : String {
        let parts = name.split(separator: "/")
        guard parts.count > 1 else { return "" }
        return String(parts[1])
    }
    
    var remote : String? {
        let parts = name.split(separator: "/")
        if parts.count > 3 {
            if parts[1] == "remotes" {
                return String(parts[2])
            }
        }
        
        return nil
    }
    
    func reference() -> R<Reference> {
        repoID.repo.flatMap{ $0.reference(name: name) }
    }
    
    var targetOID : R<OID> {
        repoID.repo | { r in r.reference(name: name) | { $0.with(r).targetOID() }}
    }
}

public enum ReferenceLocation {
    case local
    case remote
    case tag
}

public extension RepoID {
    func references(_ location: ReferenceLocation) -> R<[ReferenceID]> {
        switch location {
        case .local:
            return self.repo
                .flatMap { $0.references(withPrefix: "refs/heads/") }
                .map { $0.map { ReferenceID(repoID: self, name: $0.nameAsReference ) } }

        case .remote:
            return self.repo
                .flatMap { $0.references(withPrefix: "refs/remotes/") }
                .map { $0.map { ReferenceID(repoID: self, name: $0.nameAsReference ) } }
                .map { $0.filter { $0.displayName != "HEAD" } }
        case .tag:
            return self.repo
                .flatMap { $0.references(withPrefix: "refs/tags/") }
                .map { $0.map { ReferenceID(repoID: self, name: $0.nameAsReference ) } }
        }
    }
}



public extension ReferenceID {
    var isLocalBr: Bool { name.starts(with: "refs/heads") }
    var isRemoteBr: Bool { name.starts(with: "refs/remotes/") }

    var shortNameUnified: String {
        let partsToSkip = isLocalBr ? 2 : 3

        return name.components(separatedBy: "/")
            .dropFirst(partsToSkip)
            .joined(separator: "/")
    }
}

public extension Branch {
    func asReferenceID(repoID: RepoID) -> ReferenceID {
        return ReferenceID(repoID: repoID, name: self.nameAsReference)
    }
}


public extension ReferenceID {
    func checkout(strategy: CheckoutStrategy = .Force, progress: CheckoutProgressBlock? = nil)  -> Result<Void, Error>  {
        let brId = self
        
        
        return self.repoID.repo
            .flatMap { repo in
                repo
                    .branchLookup(name: brId.name)
                    .flatMap { branch in repo.checkout(branch: branch, strategy: strategy, progress: progress) }
            }
    }
}

extension ReferenceID: Identifiable {
    public var id: String {
        self.name
    }
}
