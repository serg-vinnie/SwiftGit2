//
//  SubmoduleID.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.09.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials


public struct SubmoduleID : Hashable {
    let repoID : RepoID
    let name: String
}

public extension SubmoduleID {
    var submodule : R<Submodule> {
        repoID.repo | { $0.submoduleLookup(named: name) }
    }
}
