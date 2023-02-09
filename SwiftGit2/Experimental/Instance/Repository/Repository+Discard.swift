//
//  Repository+Discard.swift
//  SwiftGit2-OSX
//
//  Created by loki on 15.07.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public extension Repository {
    func discardAll() -> R<()> {
        let repo = self
        
        if self.headIsUnborn {
            return self.status()
                .flatMap { $0.map { repo.discard(entry: $0 ) }.flatMap { $0 } }
                .map { _ in () }
        }
        
        
        return directoryURL
            .flatMap { url -> R<()> in
                
                return reset(.Hard)
                    | { self.statusConflictSafe(options: StatusOptions(flags: [.includeUntracked], show: .workdirOnly)) }
                    | { $0.map { $0 } | { $0.indexToWorkDirNEWFilePath } }
                    | { $0 | { url.appendingPathComponent($0) } }
                    | { $0.flatMapCatch { url -> R<()> in
                        //if is not submodule - remove it from disk
                        if !url.isDirectory {
                            return url.rm()
                        }
                        
                        return .success( () )
                    } }
                    | { _ in () }
            }
    }
    
    func discard(entries: [StatusEntry]) -> R<()> {
        entries
            .map{ discard(entry: $0) }
            .flatMap{ $0 }
            .flatMap{ _ in return .success(()) }
    }
    
}

public extension StatusEntry {
    func with(_ repo: Repository) -> Duo<StatusEntry, Repository> {
        return Duo(self, repo)
    }
}
