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
    
    public func all() -> R<[Index.Conflict]> {
        repoID.repo.flatMap{ $0.index() }
            .flatMap{ $0.conflicts() }
    }
    
    public func exist() -> R<Bool> {
        repoID.repo.flatMap { $0.index() }
            .map{ $0.hasConflicts }
    }
    
    public func resolve(path: String, type: ConflictType) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(path: path) }
        let entry = conflict | { type == .their ? $0.their : $0.our }
        
        //combine(index, entry) | { index, entry in index }
        
        index = index | { $0.removeAll(pathPatterns: [path]) } | { $0.conflictRemove(relPath: path) }
            
        _ = combine(index, entry) | { index, entry in index.add(entry) }
        
        
        return .notImplemented
    }
    
    public func resolve(path: String, resolveAsTheir: Bool) -> R<()> {
        let repo = repoID.repo.maybeSuccess!
        let index = repo.index()
        
        let rConflict: R<Index.Conflict> = all().map{ $0.filter{ $0.our.path == path || $0.their.path == path }.first! }
        
        
        
        return combine(index, rConflict)
            .flatMap { index, conflict -> R<()> in
                let sideEntry = resolveAsTheir ? conflict.their : conflict.our
                
                return index
                    .removeAll(pathPatterns: [sideEntry.path])
                    // Видаляємо конфлікт
                    .flatMap{ $0.conflictRemove(relPath: sideEntry.path) }
                    // додаємо файл чи сабмодуль в індекс
                    .flatMap {
                        $0.add(sideEntry)
                    }
                    // чекаутим файл чи сабмодуль з цього індекса
                    .flatMap { _ in
                        repo.checkout( index: index, strategy: [.Force, .DontWriteIndex])//, relPaths: [sideEntry.path] )
                    }
            }
            .flatMap{ _ in .success(()) }
    }
}

extension Index {
    func conflict(path: String) -> R<Index.Conflict> {
        conflicts() | { $0.first { $0.our.path == path || $0.their.path == path } } | { $0.asNonOptional }
    }
}
