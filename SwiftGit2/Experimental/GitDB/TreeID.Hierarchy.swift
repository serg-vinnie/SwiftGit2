//
//  TreeID.Hierarchy.swift
//  SwiftGit2-OSX
//
//  Created by loki on 22.12.2023.
//  Copyright © 2023 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials
import OrderedCollections

public extension Array where Element == TreeID {
    var hierarchy : R<TreeID.Hierarchy> {
        var children : Set<OID> = []
        var roots : OrderedDictionary<TreeID,TreeID.Cache> = [:]
        var error: Error?
        
        for treeID in self {
            treeID.cacheTrees
                .onSuccess { cache in
                    roots[treeID] = cache
                    for oid in cache.allOIDs {
                        children.insert(oid)
                        let subTreeID = TreeID(repoID: treeID.repoID, oid: oid)
                        if roots.keys.contains(subTreeID) {
                            roots[subTreeID] = nil
                        }
                    }
                }.onFailure { error = $0}
            
            if let error = error {
                return .failure(error)
            }
        }
        
        return .success(.init(children: children, roots: roots))
    }
}

extension TreeID {
    var childrenTrees : R<[TreeID]> {
        self.entries | { $0.compactMap { $0.asTreeID.maybeSuccess } }
    }
    
    public struct Hierarchy {
        public let children : Set<OID>
        public let roots : OrderedDictionary<TreeID,TreeID.Cache>
    }
}
