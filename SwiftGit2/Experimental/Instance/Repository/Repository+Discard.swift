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
        return directoryURL
            .flatMap { url -> R<()> in
                
                return reset(.Hard)
                    | { self.status(options: StatusOptions(flags: [.includeUntracked], show: .workdirOnly)) }
                    | { $0.map { $0 } | { $0.indexToWorkDirNEWFilePath } }
                    | { $0 | { url.appendingPathComponent($0) } }
                    | { $0.flatMapCatch { $0.rm() } }
                    | { _ in () }
            }
    }
    
    func discard(entry: UiStatusEntryX) -> R<Void> {
        guard let path = entry.newFileRelPath ?? entry.oldFileRelPath else { return .failure(WTF("Failed to get path for discard file changes"))  }
        
        // Stage file if mixed
        if entry.stageState == .mixed { let _ = try? self.add( relPaths: [path] ).get() }
        
        switch entry.status {
        case .current: return .success(())
        case .ignored: return .failure(WTF("Repository.discard doesn't support ignored status"))
        case .conflicted: return .failure(WTF("Repository.discard doesn't support conflicted status"))
        
        case .workTreeNew:
            return entry.with(self).indexToWorkDirNewFileURL | { $0.rm() }
        
        case .indexRenamed:
            return combine(self.index(), entry.headToIndexNEWFilePath)
                | { index, path in index.remove(paths: [path]) }
                | { entry.with(self).headToIndexNewFileURL } | { $0.rm() }
                | { entry.headToIndexOLDFilePath }
                | { self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [$0] ) }
            
        case .workTreeRenamed:
            return entry.with(self).indexToWorkDirNewFileURL
                | { $0.rm() }
                | { entry.headToIndexOLDFilePath }
                | { self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [$0] ) }
            
        case .indexNew, .indexDeleted, .indexModified, .indexTypeChange,
             .workTreeDeleted, .workTreeModified, .workTreeUnreadable, .workTreeTypeChange:
             
            return self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [path] )
            
        default:
            assert(false)
            
            return self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [path])
        }
    }
}

//    func discard(entry: UiStatusEntryX) -> R<Void> {
//        switch entry.status {
//        case .current: return .success(())
//        case .ignored: return .failure(WTF("Repository.discard doesn't support ignored status"))
//        case .conflicted: return .failure(WTF("Repository.discard doesn't support conflicted status"))
//
//        // INDEX
//        case .indexNew:
//            return combine(self.index(), entry.headToIndexNEWFilePath)
//                | { index, path in index.remove(paths: [path]) }
//                | { entry.with(self).headToIndexNewFileURL } | { $0.rm() }
//
//        case .indexDeleted, .indexModified, .indexTypeChange:
//            return entry.headToIndexNEWFilePath | { self.resetHard(paths: [$0]) }
//
//        case .indexRenamed:
//            return combine(self.index(), entry.headToIndexNEWFilePath)
//                | { index, path in index.remove(paths: [path]) }
//                | { entry.with(self).headToIndexNewFileURL } | { $0.rm() }
//                | { entry.headToIndexOLDFilePath }
//                | { self.resetHard(paths: [$0]) }
//
//            // WORK TREE
//        case .workTreeNew:
//            return entry.with(self).indexToWorkDirNewFileURL | { $0.rm() }
//
//        case .workTreeDeleted, .workTreeModified, .workTreeUnreadable, .workTreeTypeChange:
//            return entry.indexToWorkDirNEWFilePath | { self.resetHard(paths: [$0]) }
//
//        case .workTreeRenamed:
//            return entry.with(self).indexToWorkDirNewFileURL
//                | { $0.rm() }
//                | {entry.headToIndexOLDFilePath }
//                | { self.resetHard(paths: [$0]) }
//
//        default:
//            assert(false)
//            return entry.indexToWorkDirNEWFilePath | { self.resetHard(paths: [$0]) }
//        }
//
//        return .success(())
//    }
//}

public extension UiStatusEntryX {
    func with(_ repo: Repository) -> Duo<UiStatusEntryX, Repository> {
        return Duo(self, repo)
    }
}
