//
//  Repository+Staging.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 16.11.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials
import Clibgit2

public struct GitIndex {
    public let repoID: RepoID
    public init(_ repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitIndex {
    func stage(_ t: StagingTarget) -> R<Repository> {
        repoID.repo | { $0.stage(t) }
    }
    
    func unStage(_ t: StagingTarget) -> R<Repository> {
        repoID.repo | { $0.unStage(t) }
    }
}


internal extension Repository {
    func stage(_ t: StagingTarget) -> R<Repository> {
        switch t {
        case .all:
            return self.index()
                .flatMap { $0.addAll().map{ _ in () } }
                .map{ self }
        case .entry(let entry):
            guard entry.stagePath != "" else { return .wtf("Staging: can't resolve entry.stagePath") }
        
            let url = self.directoryURL | { $0.appendingPathComponent(entry.stagePath) }
            
            if case .success(let url) = url {
                if url.isDirExist {
                    return self.index()
                        .flatMap { $0.addAll(pathPatterns: ["\(entry.stagePath)"]).map{ _ in () } }
                        .map{ self }
                }
            }
            
            if entry.status.contains(.workTreeDeleted) {
                return self.remove(relPaths: [entry.stagePath])
                    .map{ self }
            } else {
                return self.addBy(path: entry.stagePath)
            }
        }
    }
    
    func unStage(_ t: StagingTarget) -> R<Repository> {
        switch t {
        case .all:
            return self.resetDefault()
                .map{ self }
            
        case .entry(let entry):
            guard entry.stagePath != "" else { return .wtf("Staging: can't resolve entry.stagePath") }
            
            return self.resetDefault(pathPatterns: [entry.stagePath])
                .map{ self }
        }
    }
}


public enum StagingTarget {
    case entry(StatusEntry)
    case all
}

internal extension Index {
    func add(_ entry: Index.Entry, inMemory: Bool = false) -> R<Index> {
        var entry1 = entry.wrappedEntry
        
        let action = _result((), pointOfFailure: "git_index_add") {
            git_index_add(self.pointer, &entry1 )
        }
        
        if inMemory {
            return action
                | { self }
        } else {
            return action
                | { self.write() }
                | { self }
        }
    }
    
    func addBy(relPath: String, inMemory: Bool = false) -> R<Index> {
        let action = git_try("git_index_add_bypath") {
            relPath.withCString { path in
                git_index_add_bypath(self.pointer, path)
            }
        }
        
        if inMemory {
            return action
                | { self }
        } else {
            return action
                | { self.write() }
                | { self }
        }
    }
    
    func addAll(pathPatterns: [String] = ["*"], inMemory: Bool = false) -> R<Index> {
        let action = git_try("git_index_add_all") {
             pathPatterns.with_git_strarray { strarray in
                 git_index_add_all(pointer, &strarray, 0, nil, nil)
             }
         }
        
        if inMemory {
            return action
                | { self }
        } else {
            return action
                | { self.write() }
                | { self }
        }
    }
    
    func removeBy(relPath: String) -> R<Index> {
        return git_try("git_index_remove_bypath") {
            relPath.withCString { path in
                git_index_remove_bypath(self.pointer, path)
            }
        } | { self.write() }
        | { .success(self) }
    }
    
    func removeAll(pathPatterns: [String] = ["*"]) -> R<Index> {
        git_try("git_index_remove_all") {
            pathPatterns.with_git_strarray { strarray in
                git_index_remove_all(pointer, &strarray, nil, nil) }
        } | { self.write() } | { self }
    }
}
