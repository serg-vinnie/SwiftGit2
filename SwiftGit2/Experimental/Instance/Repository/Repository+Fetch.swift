//
//  Repository+Fetch.swift
//  SwiftGit2-OSX
//
//  Created by loki on 28.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public enum GitTarget {
    case HEAD
    case branch(Branch)
}

public extension Repository {
    func fetch(_ target: GitTarget, options: FetchOptions = FetchOptions()) -> Result<Branch, Error> {
        switch target {
        case .HEAD:
            return HEAD()
                .flatMap { $0.asBranch() }
                .flatMap { self.fetch(.branch($0)) } // very fancy recursion
        case let .branch(branch):
            return Duo(branch, self).remote()
                .flatMap { $0.fetch(options: options) }
                .map { branch }
        }
    }
}

public extension Remote {
    func fetch(options: FetchOptions) -> Result<Void, Error> {
        return git_try("git_remote_fetch") {
            options.with_git_fetch_options {
                git_remote_fetch(pointer, nil, &$0, nil)
            }
        }
    }
}
