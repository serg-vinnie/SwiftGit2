//
//  Git.Sync.swift
//  SwiftGit2-OSX
//
//  Created by loki on 25.10.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct GitSync {
    let repoID : RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
    
    public func pull(_ target: BranchTarget, options: PullOptions, stashing: Bool = false) -> Result<MergeResult, Error> {
        repoID.repo | { $0.pull(target, options: options, stashing: stashing) }
    }
}
