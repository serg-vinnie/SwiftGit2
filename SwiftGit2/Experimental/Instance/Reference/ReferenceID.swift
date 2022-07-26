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
        } else if isRemote {
            return name.replace(of: "refs/remotes/", to: "")
        } else if isTag {
            return name.replace(of: "refs/tags/", to: "")
        }
        
        assert(false)
        return name
    }
    
//    var remote : R<String> {
//        guard isRemote else { return .wtf("can't get remote name from reference \(name)")}
//        let parts = name.split(separator: "/")
//        return .notImplemented
//    }
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
        }
    }
}
