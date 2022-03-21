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
            | { _ in () }
    }
    
    func resolveConflictAsOur(path: String) -> R<()> {
        let repo = repoID.repo
        
        return repo
            | { $0.index() }
            | { $0.conflictRemove(relPath: path) }
            | { _ in Discard(repoID: repoID).path(path) }
    }
    
    func resolveConflictAsTheir(path: String) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(path: path) }
        let sideEntry = conflict.map { $0.their }.maybeSuccess!
        
        let tmpIndex = Index.new().flatMap { $0.add(sideEntry, inMemory: true) }
            .onFailure{ print("\($0)") }
        let res = tmpIndex.flatMap { $0.entries() }.maybeSuccess!
        let sideEntryC = res.first
        
        // Видаляємо конфлікт
        index = index | { $0.conflictRemove(relPath: path) }
        // додаємо файл чи сабмодуль в індекс
        index = index | { $0.add(sideEntryC!) }
        
        // чекаутим файл чи сабмодуль з цього індекса
        return combine(repo, index)
            | { repo, index in repo.checkout(index: index, strategy: [.Force, .DontWriteIndex]) }
            | { _ in index.flatMap { $0.addBy(relPath: path) } }
            | { _ in .success(()) }
    }
}
