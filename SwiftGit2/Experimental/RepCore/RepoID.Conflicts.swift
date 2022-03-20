//
//  Conflicts.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 15.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public enum ConflictType {
    case our
    case their
    case markAsResolved
}

public struct Conflicts {
    public let repoID: RepoID
    public init(repoID: RepoID) { self.repoID = repoID }
    
//    public func all() -> R<[Index.Conflict]> {
//        repoID.repo.flatMap{ $0.index() }
//            .flatMap{ $0.conflicts() }
//    }
    
    public func exist() -> R<Bool> {
        repoID.repo.flatMap { $0.index() }
            .flatMap{ $0.conflicts() }
            .map{ $0.count > 0}
    }
    
    public func resolve(path: String, type: ConflictType) -> R<()> {
        switch type {
        case .markAsResolved:
            return resolveConflictMarkResolved(path: path)
        case .our:
            return resolveConflictAsOur(path: path)
        case .their:
            return resolveConflictAsTheir(path: path)
        }
    }
}

public extension Index {
    func conflict(path: String) -> R<Index.Conflict> {
        conflicts() | { $0.first { $0.our.path == path || $0.their.path == path } } | { $0.asNonOptional }
    }
}

fileprivate extension Conflicts {
    func resolveConflictMarkResolved(path: String) -> R<()> {
        let repo = repoID.repo
        let index = repo | { $0.index() }
        
        return index
            | { $0.conflictRemove(relPath: path) }
            | { _ in index | { $0.addBy(relPath: path) } }
    }
    
    func resolveConflictAsOur(path: String) -> R<()> {
        let repo = repoID.repo
        
        return repo
            | { $0.index() }
            | { $0.conflictRemove(relPath: path) }
            | { _ in
                repo.flatMap { $0.status() }
                .map{ $0.filter{ $0.allPaths.contains(path) } }
                .map{ $0.first }
                .flatMap { entry -> R<()> in
                    if let entry = entry {
                        return repo.flatMap { $0.discard(entry: entry) }
                    }
                    
                    return .wtf("Failed to find entry to resolve")
                }
            }
    }
    
    func resolveConflictAsTheir(path: String) -> R<()> {
        let repo = repoID.repo
        let index = repo | { $0.index() }
        
        return repo.map{ OidRevFile(repo: $0, type: .MergeHead)?.contentAsOids ?? [] }
            .map { $0.first }
            .flatMap { oid -> R<Commit> in
                if let oid = oid {
                    return repo | { $0.commit(oid: oid) }
                }
                
                return .wtf("Failed to get commit OID from MergeHead RevFile")
            }
            .flatMap { commit -> R<()> in
                index.flatMap { $0.conflictRemove(relPath: path) }
                .flatMap{ _ in
                    repo.flatMap {
                        $0.checkout(commit: commit, strategy: [.Force, .DontWriteIndex], pathspec: [path])
                    }
                }
                .flatMap { _ in index | { $0.addBy(relPath: path) } }
            }
    }
}
