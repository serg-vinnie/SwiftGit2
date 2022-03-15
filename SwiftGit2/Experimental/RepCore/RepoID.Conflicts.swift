//
//  Conflicts.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 15.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct Conflicts {
    public let repoID: RepoID
    
    public func all() -> R<[Index.Conflict]> {
        repoID.repo.flatMap{ $0.index() }
            .flatMap{ $0.conflicts() }
    }
    
    public func exist() -> R<Bool> {
        repoID.repo.flatMap { $0.index() }
            .map{ $0.hasConflicts }
    }
}
