//
//  RepCore.swift
//  SwiftGit2-OSX
//
//  Created by loki on 18.02.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct RepCore<T> {
    public let containers : [RepoID:T]
    public let roots : [RepoID:Module]
    public static var empty : RepCore<T> { RepCore(containers: [:], roots: [:]) }
}

public extension RepCore {
    func appendingRoot(repoID: RepoID) -> R<RepCore<T>> {
        roots.with(repoID: repoID) | { RepCore(containers: [:], roots: $0) }
    }
}

extension Dictionary where Key == RepoID, Value == Module {
    func with(repoID: RepoID) -> R<Self> {
        repoID.module.map { module in
            var dic = self
            dic[repoID] = module
            return dic
        }
    }
}
