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
    
    public var module          : R<Module>         { Repository.module(at: url) }
    public var exists          : Bool              { Repository.exists(at: path)                     }
    public var repo            : R<Repository>     { Repository.at(url: self.path.asURL())           }
}

extension RepoID : CustomStringConvertible {
    public var description: String { return "RepoID " + path }
}
