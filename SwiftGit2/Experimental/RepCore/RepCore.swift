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
    public let containers   : [RepoID:T]
    public let roots        : [RepoID:Module]
}

extension RepCore : CustomStringConvertible {
    public var description: String {
        "RepCore : containers \(containers.keys.map { $0.url.lastPathComponent }) roots \(roots.keys.map { $0.url.lastPathComponent })"
    }
}
 
public extension RepCore {
    static var empty : RepCore<T> { RepCore(containers: [:], roots: [:]) }
    
    func appendingRoot(repoID: RepoID, block: (RepoID)->T ) -> R<Self> {
        let module = repoID.module
        
        let newContainers   = module | { containers.with(module: $0, block: block) }
        let newRoots        = module | { roots.with(module: $0) }
        
        return combine(newContainers, newRoots) | { RepCore(containers: $0, roots: $1) }
    }
    
    func removingRoot(repoID: RepoID) -> Self {
        guard let module = roots[repoID] else { return self }
        
        var _roots = roots
        var _containers = containers
        
        for repoID in module.recurse.asRepoIDs {
            _roots[repoID] = nil
            _containers[repoID] = nil
        }
        
        return RepCore(containers: _containers, roots: _roots)
    }
}

extension Dictionary where Key == RepoID {
    func with(module: Module, block: (RepoID) -> Value) -> Self {
        var dic = self
        
        for repoID in module.recurse.asRepoIDs {
            dic[repoID] = block(repoID)
        }
        return dic
    }
}

extension Dictionary where Key == RepoID, Value == Module {
    func with(module: Module)  -> Self {
        var dic = self
        dic[module.repoID] = module
        return dic
    }
    
}
