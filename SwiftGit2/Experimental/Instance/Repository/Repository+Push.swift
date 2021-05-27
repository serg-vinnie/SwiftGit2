//
//  Repository+Push.swift
//  SwiftGit2-OSX
//
//  Created by loki on 27.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension Repository {
    func push(options: PushOptions = PushOptions()) -> Result<(), Error> {
        let branch = self.HEAD()
            .flatMap { $0.asBranch() }
            
        let remote = branch
            .flatMap { Duo($0,self).remote() }
        
        return combine(remote, branch)
            .flatMap { $0.push(branchName: $1.name, options: options) }
    }
    
    func push(remoteName: String, branchName: String, options: PushOptions) -> Result<(), Error> {
        remote(name: remoteName)
            .flatMap { $0.push(branchName: branchName, options: options) }
    }
}

extension Remote {
    func push(branchName: String, options: PushOptions ) -> Result<(), Error> {
        print("Trying to push ''\(branchName)'' to remote ''\(self.name)'' with URL:''\(self.url)''")
        
        return git_try("git_remote_push") {
            options.with_git_push_options { push_options in
                [branchName].with_git_strarray { strarray in
                    git_remote_push(self.pointer, &strarray, &push_options)
                }
            }
        }
    }
}

public extension Duo where T1 == Branch, T2 == Remote {
    /// Push local branch changes to remote branch
    func push(auth: Auth = .auto) -> Result<(), Error> {
        let (branch, remote) = value
        return remote.push(branchName: branch.name, options: PushOptions(auth: auth) )
    }
}