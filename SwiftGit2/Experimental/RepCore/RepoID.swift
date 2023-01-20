//
//  RepoID.swift
//  SwiftGit2-OSX
//
//  Created by loki on 17.02.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct RepoID : Hashable {
    public let path: String
    public var url: URL { path.asURL() }
    
    public init(path: String) { self.path = path.skippingLastSlash }
    public init(url: URL)     { self.path = url.path.skippingLastSlash }
    
    public var displayName     : String            { url.lastPathComponent }
    public var module          : R<GitModule>      { Repository.module(at: url) }
    public var exists          : Bool              { Repository.exists(at: path)                     }
    public var repo            : R<Repository>     { Repository.at(url: self.path.asURL(), fixDetachedHead: false)           }
}

public extension RepoID {
    var flatTree: [RepoID] {
        (module
                | { $0.recurse }
                | { $0.filter { $0.value?.exists ?? false }.asRepoIDs }
        ).maybeSuccess ?? []
    }
}


extension RepoID : Identifiable {
    public var id: String { self.path }
}

extension RepoID : CustomStringConvertible {
    #if DEBUG
    public var description: String { "RepoID " + path.replace(of: "/Users/loki/dev", to: "􀋀").replace(of: "Carthage/Checkouts", to: "􀋀") }
    #else
    public var description: String { "RepoID " + path }
    #endif
}
