import Foundation
import Essentials

public struct GitDiscard {
    public let repoID : RepoID
    public init(repoID : RepoID) { self.repoID = repoID }
    
    public func entry( _ entry: StatusEntry) -> R<Void> {
        repoID.repo | { $0.discard(entry: entry) }
    }
    
    public func path( _ path: String) -> R<Void> {
        repoID.repo | { repo in
            repo.status()
                | { $0.first { $0.allPaths.contains(path) } }
                | { $0.asNonOptional("discard failed to find path: \(path)") }
                | { repo.discard(entry: $0) }
        }
    }
    
    public func paths( _ path: [String]) -> R<Void> {
        repoID.repo | { repo in
            repo.status()
                .map { $0.filter { path.contains( $0.stagePath ) } }
                .map { entries in entries.map { repo.discard(entry: $0) } }
                .flatMap { $0.flatMap{ $0 }.map{ _ in () } }
        }
    }
    
    public func all() -> R<Void> {
        repoID.repo | { repo in
            repo.discardAll()
        }
    }
}

extension Repository {
    func discard(entry: StatusEntry) -> R<Void> {
        let paths = entry.allPaths.compactMap{ $0 }.distinct()
        
        switch entry.status {
        case .current: return .success(())
        case .ignored: return .failure(WTF("Repository.discard doesn't support ignored status"))
        case .conflicted: return .failure(WTF("Repository.discard doesn't support conflicted status"))
        
        case .workTreeNew:
            return entry.with(self).indexToWorkDirNewFileURL | { $0.rm() }
        
        case .indexRenamed:
            return combine(self.index(), entry.headToIndexNEWFilePath)
                | { index, path in index.removeAll(pathPatterns: paths) }
                | { _ in entry.with(self).headToIndexNewFileURL }
                | { $0.rm() }
                | { entry.headToIndexOLDFilePath }
                | { self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [$0] ) }
            
        case .workTreeRenamed:
            return entry.with(self).indexToWorkDirNewFileURL
                | { $0.rm() }
                | { entry.headToIndexOLDFilePath }
                | { self.checkoutHead(strategy: [.Force], progress: nil, pathspec: [$0] ) }
            
        case .indexNew, .indexDeleted, .indexModified, .indexTypeChange,
             .workTreeDeleted, .workTreeModified, .workTreeUnreadable, .workTreeTypeChange:
             
            return self.checkoutHead(strategy: [.Force], progress: nil, pathspec: paths )
            
        default:
            print("discard(entry) -- HORRIBLE ERROR? Or not?")
            
            //assert(false)
            // Stage file if mixed? Maybe some another situations?
            return self.checkoutHead(strategy: [.Force], progress: nil, pathspec: paths)
        }
    }
}
