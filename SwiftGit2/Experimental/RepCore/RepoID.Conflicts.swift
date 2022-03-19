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
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(path: path) }
        let sideEntry = conflict | { type == .their ? $0.their : $0.our }
        
        // Видаляємо конфлікт
        index = index | { $0.conflictRemove(relPath: path) }
        // додаємо файл чи сабмодуль в індекс
        index = combine(index, sideEntry)
            .flatMap { index, sideEntry in index.add(sideEntry)  }
        
        // чекаутим файл чи сабмодуль з цього індекса
        return combine(repo, index)
            | { repo, index in repo.checkout(index: index, strategy: [.Force, .DontWriteIndex]) }
            | { _ in index | { $0.addBy(relPath: path) } }
    }
}

public extension Index {
    func conflict(path: String) -> R<Index.Conflict> {
        conflicts() | { $0.first { $0.our.path == path || $0.their.path == path } } | { $0.asNonOptional }
    }
}
