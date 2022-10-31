//
//  Repository+Fetch.swift
//  SwiftGit2-OSX
//
//  Created by loki on 28.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation
import Essentials

public extension Repository {
    func fetch(_ target: BranchTarget, options: FetchOptions) -> Result<Branch, Error> {
        let duo = target.with(self)
        return duo.remote | { $0.fetch(options: options) } | { duo.branchInstance }
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

public extension Repository {
    func upstreamExistsFor(_ target: BranchTarget) -> R<Bool> {
        return target.branch(in: self)
            .flatMap { $0.upstream() }
            .map { _ in true }
            .flatMapError {
                if $0.isGit2(func: "git_branch_upstream", code: -3) {
                    return .success(false)
                }
                return .failure($0)
            }
    }
}