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
}

public extension GitConflicts {
//    public func all() -> R<[Index.Conflict]> {
//        repoID.repo.flatMap{ $0.index() }
//            .flatMap{ $0.conflicts() }
//    }
    
    func exist() -> R<Bool> {
        repoID.repo.flatMap { $0.index() }
            .flatMap{ $0.conflicts() }
            .map{ $0.count > 0}
    }
    
    func resolve(path: String, side: ConflictSide, type: ConflictType) -> R<()> {
        switch side {
        case .markAsResolved:
            return resolveConflictMarkResolved(path: path)
        case .our:
            return resolveConflictAsOur(path: path, type: type)
//            return resolveConflictSubmodule(path: path, side: .our)
        case .their:
            if type == .file {
                return resolveConflictAsTheirFile(path: path)
            }
            
            return resolveConflictSubmodule(path: path, side: .their)
        }
    }
    
    @available(*, deprecated, message: "Shit-code, but it works")
    func getOIDForSubmoduleConflict(path: String, side: ConflictSide) -> R<OID> {
        XR.Shell.Git(repoID: repoID)
            .run(args: ["ls-files", "-u", path]) // git ls-files -u sub_repo_path
            .flatMap { $0.getSha(side: side) }
    }
}

public extension Index {
    func conflict(path: String) -> R<Index.Conflict> {
        conflicts()
            | { $0.first { $0.our?.path == path || $0.their?.path == path } }
        | { $0.asNonOptional }
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
    
    func resolveConflictAsOur(path: String, type: ConflictType) -> R<()> {
        let conflictRemoveR =
            repoID.repo
                | { $0.index() }
                | { $0.conflictRemove(relPath: path) }
        
        switch type {
        case .file:
             return conflictRemoveR
                | { _ in GitDiscard(repoID: repoID).path(path) }
            
        case .submodule:
            return conflictRemoveR
            .flatMap { _ in repoID.repo }
            .flatMap { repo in
                repo.index().flatMap{ $0.addBy(relPath: path) }
            }
            .map{ _ in () }
        }
    }
    
    func resolveConflictAsTheirFile(path: String) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(path: path) }
        
        let tmpIndex = conflict
            .flatMap { $0.their.asNonOptional }
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
    
    func resolveConflictAsTheirSubmoduleOLD(path: String) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        
        let submodCommitOid = index
            .flatMap { $0.conflict(path: path) }
            .map { $0.their?.oid }
            .flatMap { $0.asNonOptional }
        
        // Видаляємо конфлікт
        index = index | { $0.conflictRemove(relPath: path) }
        
        let submoduleRepo = repoID.module
            .map{ $0.subModules }
            .map{ $0.filter{ $0.key == path } }
            .map{ $0.first! }
            .map{ $0.value! }
            .map{ $0.repoID.url.deletingLastPathComponent() }
            .flatMap{ Repository.at(url: $0) }
        
        let submoduleCommit = combine(submoduleRepo, submodCommitOid)
            .flatMap { submoduleRepo, submodCommitOid in
                submoduleRepo.commit(oid: submodCommitOid)
            }
        
        return combine(submoduleRepo, submoduleCommit)
            .flatMap { subModRepo, commit in
                subModRepo.checkout(commit: commit, strategy: [.Force], progress: nil, pathspec: [path], stashing: false)
            }
            .flatMap{ _ in repo }
            .flatMap{ $0.status() }
            .map{ $0.filter { $0.stagePath == path } }
            .flatMap{ entries in
                entries.flatMap { entry in repo.map{ $0.unStage(.entry(entry)) } }
            }
            .flatMap{ _ in .success(())}
    }
    
    @available(*, deprecated, message: "Shit-code, but it works")
    func resolveConflictSubmodule(path: String, side: ConflictSide) -> R<()> {
        let submodRepoId = repoID.treeAllChildren
            .filter { $0.url.path == repoID.url.appending(path: path).path }
            .first
            .asNonOptional
        
        let submodStatusEntriesCount = submodRepoId
            .flatMap{ $0.repo }
            .flatMap{ $0.status() }
            .map{ $0.count }
        
        return getOIDForSubmoduleConflict(path: path, side: side)
            .flatMap { oid in
                resolveConflictAsOur(path: path, type: .submodule)
                    .flatMap { _ in
                        //Submodule: soft checkout of "oid" + discardAll if there are no changes
                        combine(submodRepoId, submodStatusEntriesCount)
                            .flatMap{ input -> R<RepoID> in
                                let (repoId, repoChangesCount) = input
                                
                                if repoChangesCount > 0 {
                                    return .failure(WTF("Cannot resolve conflict as Theirs. There are changes in submodule at location: \(path)"))
                                }
                                
                                return .success(repoId)
                            }
                            .flatMap {
                                $0.repo.flatMap{ $0.checkout(oid, options: .init()) }
                            }.flatMap{
                                submodRepoId
                            }
                            .flatMap {
                                $0.repo.flatMap{ $0.discardAll() }
                            }
                    }
            }
            .flatMap { _ in
                repoID.repo
                    .flatMap{ $0.addBy(path: path) }
                    .map{ _ in () }
            }
    }
}

//
// Helpers
//

fileprivate extension String {
    func getSha(side: ConflictSide) -> R<OID> {
        let row: String? = self
            .split(separator: "\n")
            .dropFirst(side == .our ? 1 : 2)
            .first?
            .asStr()
        
        return row.asNonOptional
            .map{ $0.split(bySeparators: [" ","\t"]).dropFirst().first }
            .flatMap{ $0.asNonOptional }
            .flatMapError{ _ in // fix error of asNonOptional
                .failure(WTF("Failed to get sha of \(side) submodule conflict"))
            }
            .flatMap { sha in
                OID(string: sha).asNonOptional
            }
    }
}
