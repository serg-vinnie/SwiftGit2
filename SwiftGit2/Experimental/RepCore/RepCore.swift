//
//  RepCore.swift
//  SwiftGit2-OSX
//
//  Created by loki on 18.02.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

protocol RepoContainer {
    var repoID : RepoID { get }
}

public struct RepCore<T> {
    public let containers : [RepoID:T]
    public let roots : [RepoID:Module]
    public static var empty : RepCore<T> { RepCore(containers: [:], roots: [:]) }
}

extension RepCore : CustomStringConvertible {
    public var description: String {
        "RepCore : containers \(containers.keys.map { $0.url.lastPathComponent }) roots \(roots.keys.map { $0.url.lastPathComponent })"
    }
}
 
public extension RepCore {
    func appendingRoot(repoID: RepoID, block: (RepoID)->T ) -> R<RepCore<T>> {
        let module = repoID.module
        
        let newContainers   = module | { containers.with(module: $0, block: block) }
        let newRoots        = module | { roots.wit(module: $0) }
        
        return combine(newContainers, newRoots) | { RepCore(containers: $0, roots: $1) }
    }
}

extension Dictionary where Key == RepoID {
    func with(module: Module, block: (RepoID) -> Value) -> Self {
        var dic = self
        
        for item in module.recurse.values.compactMap({ $0 }) {
            dic[item.repoID] = block(item.repoID)
        }
        return dic
    }
}

extension Dictionary where Key == RepoID, Value == Module {
    func wit(module: Module)  -> Self {
        var dic = self
        dic[module.repoID] = module
        return dic
    }
    
}
