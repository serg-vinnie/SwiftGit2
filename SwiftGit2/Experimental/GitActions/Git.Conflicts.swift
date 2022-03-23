//
//  Conflicts.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 15.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public enum ConflictSide {
    case our
    case their
    case markAsResolved
}

public enum ConflictType {
    case file
    case submodule
}

public struct GitConflicts {
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
    
    public func resolve(path: String, side: ConflictSide, type: ConflictType = .file) -> R<()> {
        switch side {
        case .markAsResolved:
            return resolveConflictMarkResolved(path: path)
        case .our:
            return resolveConflictAsOur(path: path)
        case .their:
            return resolveConflictAsTheir(path: path, type: type)
        }
    }
}

public extension Index {
    func conflict(path: String) -> R<Index.Conflict> {
        conflicts() | { $0.first { $0.our.path == path || $0.their.path == path } } | { $0.asNonOptional }
    }
}

fileprivate extension GitConflicts {
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
            | { _ in GitDiscard(repoID: repoID).path(path) }
    }
    
    func resolveConflictAsTheir(path: String, type: ConflictType) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(path: path) }
        
        let tmpIndex = conflict.map { $0.their }
            .flatMap{ sideEntry in
                Index.new().flatMap { $0.add(sideEntry, inMemory: true) }
            }
            .onFailure { print("\($0)") }
        
        let tmpIndexFirstEntry = tmpIndex.flatMap { $0.entries().map{ $0.first } }
        
        // Видаляємо конфлікт
        index = index | { $0.conflictRemove(relPath: path) }
        
        // додаємо файл чи сабмодуль в індекс з тимчасового індекса
        index = tmpIndexFirstEntry.flatMap { sideEntryC -> R<Index> in
            guard let sideEntryC = sideEntryC
            else {return .wtf("Failed to get .THEIR entry from temp index")  }
            
            return index | { $0.add(sideEntryC) }
        }
        
        // чекаутим файл чи сабмодуль з цього індекса
        return combine(repo, index)
            | { repo, index in repo.checkout(index: index, strategy: [.Force, .DontWriteIndex]) }
            | { _ in index.flatMap { $0.addBy(relPath: path) } }
            | { _ in .success(()) }
    }
}
