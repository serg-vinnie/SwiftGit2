//
//  RepoID.Unborn.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials
import Clibgit2

public struct Unborn {
    public let repoID : RepoID
    public init(repoID: RepoID) { self.repoID = repoID }
    public init(repoURL: URL) { self.repoID = RepoID(url: repoURL)}
}

public extension Unborn {
    func cloneNext(auth: Auth) -> R<GitModule.Progress> {
        let options = SubmoduleUpdateOptions(fetch: FetchOptions(auth: auth))
        return repoID.module | { $0.next(options: options) }
    }
    
    func clone(from remoteURL: String, auth: Auth) -> R<Repository> {
        let options = CloneOptions(fetch: FetchOptions(auth: auth))
        return clone(from: remoteURL, options: options)
    }
    
    func clone(from remoteURL: String, options: CloneOptions) -> R<Repository> {
        print("clone started")
        let t = git_instance(of: Repository.self, "git_clone") { pointer in
            options.with_git_clone_options { clone_options in
                git_clone(&pointer, remoteURL, repoID.path, &clone_options)
            }
        }
        print("clone ended")
        return t
    }
    
    func clone(from remoteURL: URL, options: CloneOptions) -> R<Repository> {
        let str = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString
        return clone(from: str, options: options)
    }
}
