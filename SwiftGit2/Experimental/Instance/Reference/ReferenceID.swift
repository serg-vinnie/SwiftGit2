//
//  ReferenceID.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.07.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct ReferenceID {
    public let repoID: RepoID
    public let name: String
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
    
    var remote : String? {
        let parts = name.split(separator: "/")
        if parts.count > 3 {
            if parts[1] == "remotes" {
                return String(parts[2])
            }
        }
        
        return nil
    }
}

public extension RepoID {
    func references(_ location: BranchLocation) -> R<[ReferenceID]> {
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
        }
    }
}
