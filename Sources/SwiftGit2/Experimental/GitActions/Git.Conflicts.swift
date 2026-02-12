
import Foundation
import Essentials

public enum ConflictEntries {
    case our
    case their
    case ancestor
}

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
    func allConflictPaths() -> R<[String]> {
        repoID.repo.flatMap{ $0.index() }
            .flatMap{ $0.conflicts() }
    }
    
    var count: R<Int> {
        repoID.repo.flatMap{ $0.index() }
            .flatMap{ $0.conflicts() }
            .map{ $0.count }
    }
    
    func exist() -> R<Bool> {
        repoID.repo.flatMap{ $0.index() }.map{ $0.hasConflicts }
    }
    
    func resolve(path: String, side: ConflictSide, type: ConflictType) -> R<()> {
        switch side {
        case .markAsResolved:
            return resolveConflictMarkResolved(path: path)
        case .our:
            return resolveConflictCli(relPath: path, asSide: .our)
        case .their:
            switch type{
            case .file:
                return resolveConflictCli(relPath: path, asSide: .their)
            case .submodule:
                return resolveConflictSubmodule(path: path, side: .their)
            }
        }
    }
    
    @available(*, deprecated, message: "Shit-code, but it works")
    func getOIDForSubmoduleConflict(path: String, side: ConflictSide) -> R<OID> {
        XR.Shell.Git(repoID: repoID)
            .run(args: ["ls-files", "-u", path]) // git ls-files -u sub_repo_path
            .flatMap { $0.getSha(side: side) }
    }
}

//
// Logic
//

fileprivate extension GitConflicts {
    func resolveConflictMarkResolved(path: String) -> R<()> {
        let repo = repoID.repo
        let index = repo | { $0.index() }
        
        return index
            | { $0.conflictRemove(relPath: path) }
            | { _ in index | { $0.addBy(relPath: path) } }
            | { _ in () }
    }
    
    func resolveConflictCli(relPath: String, asSide side: ConflictEntries) -> R<()> {
        switch side {
        case .our:
            return XR.Shell.Git(repoID: repoID )
                .run(args: ["checkout", "--ours", relPath])
                .flatMap{ _ in
                    XR.Shell.Git(repoID: repoID )
                        .run(args: ["add", relPath])
                }
                .asVoid
        case .their:
            return XR.Shell.Git(repoID: repoID )
                .run(args: ["checkout", "--theirs", relPath])
                .flatMap{ _ in
                    XR.Shell.Git(repoID: repoID )
                        .run(args: ["add", relPath])
                }
                .asVoid
        case .ancestor:
            return .failure(WTF("not supported"))
        }
    }
    
    @available(*, deprecated, message: "Shit-code, but it works")
    func resolveConflictSubmodule(path: String, side: ConflictSide) -> R<()> {
        let submodRepoId = repoID.treeAllChildren
            .filter { $0.url.path == repoID.url.appending(path: path).path }
            .first
            .asNonOptional
        
        // Check if there are no changes in Submodule + get "Theirs" oid
        return submodRepoId
            .flatMap{ $0.repo }
            .flatMap{ $0.status() }
            .map{ $0.count }
            .flatMap{ repoChangesCount -> R<OID> in
                if repoChangesCount > 0 {
                    return .failure(WTF("Cannot resolve conflict as \(side). There are changes in submodule at location: \(path)"))
                }
                
                return getOIDForSubmoduleConflict(path: path, side: side)
            }
            // Resolve conflict as "Ours" in parent repo
            // + Submodule: soft checkout of  commit with "oid" + discardAll
            // It is safe as there was no changes
            .flatMap { oid in
                resolveConflictCli(relPath: path, asSide: .our)
                    .flatMap { _ in
                        submodRepoId
                            .flatMap {
                                $0.repo.flatMap{ $0.checkout(oid, options: .init()) }
                            }
                            .flatMap { submodRepoId }
                            .flatMap { $0.repo.flatMap{ $0.discardAll() } }
                    }
            }
            // stage repo with changed submodule
            .flatMap {
                repoID.repo
                    .flatMap{ $0.addBy(path: path) }
                    .map{ _ in () }
            }
    }
}

//
// Not used at the moment
// "swiftGit2" resolve conflict - can be used instead of Cli version
//

fileprivate extension GitConflicts {
    
    // most new code
    // you can try to improve code from this point. Test it on advanced conflicts
    @available(*, deprecated, message: "Make sure you doing what you need, better not use me")
    func resolveConflictFileNewest(path: String, asSide side: ConflictEntries) -> R<()> {
//        let st1 = repoID.repo.flatMap{ $0.status() }.map{ $0.map{ $0 } }
//        print(st1)
        
        let rez = repoID.repo
            .flatMap{ $0.index() }
            .flatMap{ $0.conflictResolve(relPath: path, asSide: side) }
            .asVoid
        
        //let st = repoID.repo.flatMap{ $0.status() }.map{ $0.map{ $0 } }
        
        return rez
    }
    
    @available(*, deprecated, message: "Make sure you doing what you need, better not use me")
    func resolveConflictAsTheirFile(path: String) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        let conflict = index | { $0.conflict(relPath: path) }
        
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
    
    @available(*, deprecated, message: "Make sure you doing what you need, better not use me")
    func resolveConflictAsOur(path: String, type: ConflictType) -> R<()> {
        let conflictRemoveR =
            repoID.repo
                | { $0.index() }
                | { $0.conflictRemove(relPath: path) }
        
        switch type {
        case .file:
            let r1 = conflictRemoveR
                .flatMap { _ in repoID.repo }
                .flatMap { $0.status()  }
                .map { $0.map{ $0.stagePath } }
            
            let r2 = conflictRemoveR
                .flatMap { $0.entries() }
                .map{ $0.map{ $0.path } }
            
            return combine(r1, r2)
                .map{ $0.0.appending(contentsOf: $0.1) }
                .flatMap{ statusPaths in
                    if statusPaths.contains(path) {
                        return GitDiscard(repoID: repoID).path(path)
                    } else {
                        return.success(())
                    }
                }
            
        case .submodule:
            return conflictRemoveR
            .flatMap { _ in repoID.repo }
            .flatMap { repo in
                repo.index().flatMap{ $0.addBy(relPath: path) }
            }
            .map{ _ in () }
        }
    }
    
    @available(*, deprecated, message: "Make sure you doing what you need, better not use me")
    func resolveConflictAsTheirSubmoduleOLD(path: String) -> R<()> {
        let repo = repoID.repo
        var index = repo | { $0.index() }
        
        let submodCommitOid = index
            .flatMap { $0.conflict(relPath: path) }
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
