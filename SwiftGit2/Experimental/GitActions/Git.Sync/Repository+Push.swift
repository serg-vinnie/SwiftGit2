//
//  Repository+Push.swift
//  SwiftGit2-OSX
//
//  Created by loki on 27.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

extension Repository {
    func push(_ target: BranchTarget, options: PushOptions) -> R<Void> {
        let branch = target.with(self).branchInstance
        let remote = target.with(self).remote

        return combine(remote, branch) | { $0.push(refspec: $1.nameAsReference, options: options) }
    }

//    func push(remoteName: String, refspec: String, options: PushOptions) -> Result<Void, Error> {
//        remote(name: remoteName) | { $0.push(refspec: refspec, options: options) }
//    }
}

public extension Remote {
    var push_refspec : R<[String]> {
        var strarray = git_strarray()
        return git_try("git_remote_get_fetch_refspecs") {
            git_remote_get_push_refspecs(&strarray, self.pointer)
        } | { _ in strarray.map { $0 } }
    }
    
    var fetch_refspec : R<[String]> {
        var strarray = git_strarray()
        return git_try("git_remote_get_fetch_refspecs") {
            git_remote_get_fetch_refspecs(&strarray, self.pointer)
        } | { _ in strarray.map { $0 } }
    }
    
    func push(refspec: String, options: PushOptions) -> R<Void> {
        push(refspec: [refspec], options: options)
    }
        
    func push(refspec: [String], options: PushOptions) -> R<Void> {
        print("Trying to push ''\(refspec)'' to remote ''\(name)'' with URL:''\(url)''")
        return //self.connect(direction: .push, callbacks: options.callbacksConnect)
//        | { _ in
            git_try("git_remote_push") {
                options.with_git_push_options { push_options in
                    refspec.with_git_strarray { strarray in
                        git_remote_push(self.pointer, &strarray, &push_options)
                    }
                }
            }
//        }
    }
}

public extension Duo where T1 == Branch, T2 == Remote {
    /// Push local branch changes to remote branch
    func push(auth: Auth) -> R<Void> {
        let (branch, remote) = value
        return remote.push(refspec: branch.nameAsReference, options: PushOptions(auth: auth))
    }
}

public extension Duo where T1 == ReferenceID, T2 == Remote {
    /// Push local branch changes to remote branch
    func push(auth: Auth) -> R<Void> {
        let (ref, remote) = value
        
        guard ref.isBranch else { return .wtf("Duo.push() failed: Reference is not a branch!") }
        
        return remote.push(refspec: ref.name, options: PushOptions(auth: auth))
    }
}

