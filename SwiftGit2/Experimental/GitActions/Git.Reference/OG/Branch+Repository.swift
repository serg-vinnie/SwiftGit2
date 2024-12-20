//
//  Branch+Repository.swift
//  SwiftGit2-OSX
//
//  Created by loki on 30.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension Duo where T1 == Branch, T2 == Repository {

    /// Gets REMOTE item from local branch. Doesn't works with remote branch

}

public extension Repository {
    func remoteName(localBr: String) -> R<String> {
        var buf = git_buf(ptr: nil, asize: 0, size: 0)
        
        return git_try("git_branch_upstream_remote") {
            git_branch_upstream_remote(&buf, self.pointer, localBr)
        }.flatMap { Buffer(buf: buf).asString() }
    }
    
    func remoteName(upstream: String) -> R<String> {
        var buf = git_buf(ptr: nil, asize: 0, size: 0)
        
        return git_try("git_branch_remote_name") {
            git_branch_remote_name(&buf, self.pointer, upstream)
        }.flatMap { Buffer(buf: buf).asString() }
    }
    
    
    func remote(localBr: String) -> R<Remote> {
        let repo = self
        
        return repo.remoteName(localBr: localBr)
            .flatMap { remoteName in repo.remote(name: remoteName) }
    }
    
    func remote(upstream: String) -> R<Remote> {
        let repo = self
        
        return repo.remoteName(upstream: upstream)
            .flatMap { remoteName in repo.remote(name: remoteName) }
    }
}
