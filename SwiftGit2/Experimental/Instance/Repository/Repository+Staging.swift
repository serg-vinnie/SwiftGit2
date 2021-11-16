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
            guard let path = entry.pathInWorkDir else { return .wtf("Staging: can't resolve entry.pathInWorkDir") }
            
            if entry.status.contains(.workTreeDeleted) {
                return self.resetDefault(pathPatterns: [path])
                    .map{ self }
            } else {
                return self.addBy(path: path)
            }
        }
    }
    
    func unStage(_ t: StagingTarget) -> R<Repository> {
        switch t {
        case .all:
            return self.resetDefault()
                .map{ self }
            
        case .entry(let entry):
            if let path = entry.pathInWorkDir {
                return self.resetDefault(pathPatterns: [path])
                    .map{ self }
            }
            
            return .wtf("Fuck")
        }
    }
}


public enum StagingTarget {
    case entry(StatusEntry)
    case all
}
