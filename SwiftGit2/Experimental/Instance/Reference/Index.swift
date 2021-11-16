//
//  IndexInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public final class Index: InstanceProtocol, DuoUser {
    public var pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_index_free(pointer)
    }
}

public extension Repository {
    func index() -> Result<Index, Error> {
        var pointer: OpaquePointer?
        
        return _result({ Index(pointer!) }, pointOfFailure: "git_repository_index") {
            git_repository_index(&pointer, self.pointer)
        }
    }
}

public extension Index {
    var entrycount: Int { git_index_entrycount(pointer) }

    var hasConflicts: Bool { git_index_has_conflicts(pointer) == 1 }

    func entries() -> Result<[Index.Entry], Error> {
        var entries = [Index.Entry]()
        for i in 0 ..< entrycount {
            if let entry = git_index_get_byindex(pointer, i) {
                entries.append(Index.Entry(entry: entry.pointee))
            }
        }
        return .success(entries)
    }
    
    func conflicts() -> Result<[Conflict], Error> {
        conflictIterator().flatMap { $0.all() }
    }
    
    private func conflictIterator() -> Result<ConflictIterator, Error> {
        return git_instance(of: ConflictIterator.self, "git_index_conflict_iterator_new"){ iterator in
            git_index_conflict_iterator_new(&iterator, self.pointer)
        }
    }
    
    func add(_ entry: Index.Entry) -> R<()> {
        var entry1 = entry.wrappedEntry
        
        return _result((), pointOfFailure: "git_index_add") {
            git_index_add(self.pointer, &entry1 )
        } | { self.write() }
    }
    
    func addBy(relPath: String) -> R<()> {
        return git_try("git_index_add_bypath") {
            relPath.withCString { path in
                git_index_add_bypath(self.pointer, path)
            }
        } | { self.write() }
    }
    
    func addAll(pathPatterns: [String] = ["*"]) -> R<()> {
         git_try("git_index_add_all") {
             pathPatterns.with_git_strarray { strarray in
                 git_index_add_all(pointer, &strarray, 0, nil, nil)
             }
         }
    }
    
    func removeBy(relPath: String) -> R<()> {
        return git_try("git_index_remove_bypath") {
            relPath.withCString { path in
                git_index_remove_bypath(self.pointer, path)
            }
        } | { self.write() }
    }
    
    func removeAll(pathPatterns: [String] = ["*"]) -> Result<Void, Error> {
        git_try("git_index_remove_all") {
            pathPatterns.with_git_strarray { strarray in
                git_index_remove_all(pointer, &strarray, nil, nil) }
        } | { self.write() }
    }
    
    func conflictRemove(relPath: String) -> R<()> {
        return _result({ () }, pointOfFailure: "git_index_conflict_remove") {
            relPath.withCString { path in
                git_index_conflict_remove(self.pointer, path);
            }
        } | { self.write() }
    }
    
    func conflictRemoveAll() -> R<()> {
        return git_try("git_index_conflict_cleanup") {
            git_index_conflict_cleanup(self.pointer)
        } | { self.write() }
    }

    func clear() -> Result<Void, Error> {
        _result((), pointOfFailure: "git_index_clear") { git_index_clear(pointer) }
    }

    internal func write() -> Result<Void, Error> {
        git_try("git_index_write") { git_index_write(pointer) }
    }

    func writeTree() -> Result<git_oid, Error> {
        var treeOID = git_oid() // out

        return _result({ treeOID }, pointOfFailure: "git_index_write_tree") {
            git_index_write_tree(&treeOID, self.pointer)
        }
    }

    func writeTree(to repo: Repository) -> Result<Tree, Error> {
        var oid = git_oid()
        return git_try("git_index_write_tree_to") {
            git_index_write_tree_to(&oid, self.pointer, repo.pointer)
        }.flatMap { repo.treeLookup(oid: OID(oid)) }
    }
}

public extension Duo where T1 == Index, T2 == Repository {
    /// Use Repo.Commit instead!
    func commit(message: String, signature: Signature) -> Result<Commit, Error> {
        let (index, repo) = value
        
        let otherParentsR = OidRevFile( repo: repo, type: .MergeHead )?
            .contentAsOids
            .flatMap { repo.commit(oid: $0) } ?? .success([])
        
        let treeOidR = index.writeTree()
        
        return combine(treeOidR, otherParentsR)
            .flatMap { treeOID, otherParents in
                repo.headCommit()
                    // If commit exist
                    .flatMap { commit in
                        let parents: [Commit] = [commit].appending(contentsOf: otherParents)
                        
                        return repo.commit(tree: OID(treeOID), parents: parents, message: message, signature: signature)
                    }
                    // if there are no parents: initial commit
                    .flatMapError { _ in
                        repo.commit(tree: OID(treeOID), parents: [], message: message, signature: signature)
                    }
            }
            // RevFiles cleanup
            .flatMap { commit in
                repo.stateClean()
                    .map { _ in commit}
            }
    }
}

internal extension Repository {
    /// If no parents write "[]"
    /// Perform a commit with arbitrary numbers of parent commits.
    func commit(tree treeOID: OID, parents: [Commit], message: String, signature: Signature) -> Result<Commit, Error> {
        return treeLookup(oid: treeOID)
            .flatMap { self.commitCreate(signature: signature, message: message, tree: $0, parents: parents) }
    }

    func treeLookup(oid: OID) -> Result<Tree, Error> {
        var oid = oid.oid

        return git_instance(of: Tree.self, "git_tree_lookup") { pointer in
            git_tree_lookup(&pointer, self.pointer, &oid)
        }
    }
}

internal extension Repository {
    func commitCreate(signature: Signature, message: String, tree: Tree, parents: [Commit]) -> Result<Commit, Error> {
        var outOID = git_oid()
        let parentsPointers: [OpaquePointer?] = parents.map { $0.pointer }

        return combine(signature.make(), Buffer.prettify(message: message))
            .flatMap { signature, buffer in
                git_try("git_commit_create") {
                    parentsPointers.withUnsafeBufferPointer { unsafeBuffer in
                        let parentsPtr = UnsafeMutablePointer(mutating: unsafeBuffer.baseAddress)
                        return git_commit_create(&outOID, self.pointer, "HEAD", signature.pointer, signature.pointer,
                                                 "UTF-8", buffer.buf.ptr, tree.pointer, parents.count, parentsPtr)
                    }
                }
            }.flatMap { self.instanciate(OID(outOID)) }
    }
}
