//
//  Repository+Staging.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 16.11.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public extension Repository {
    func stage(_ t: StagingTarget) -> R<Repository> {
        switch t {
        case .all:
            return self.index()
                .flatMap { $0.addAll() }
                .map{ self }
        case .entry(let entry):
            guard entry.stagePath != "" else { return .wtf("Staging: can't resolve entry.stagePath") }
        
            let url = self.directoryURL | { $0.appendingPathComponent(entry.stagePath) }
            
            if case .success(let url) = url {
                if url.isDirExist {
                    return self.index()
                        .flatMap { $0.addAll(pathPatterns: ["\(entry.stagePath)"]) }
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
