import Foundation
import Essentials

public struct Discard {
    public let repoID : RepoID
    public init(repoID : RepoID) { self.repoID = repoID }
    
    func entry( _ entry: StatusEntry) -> R<Void> {
        repoID.repo | { $0.discard(entry: entry) }
    }
    
    func path( _ path: String) -> R<Void> {
        repoID.repo | { repo in
            repo.status()
                | { $0.first { $0.allPaths.contains(path) } }
                | { $0.asNonOptional("discard failed to find path: \(path)") }
                | { repo.discard(entry: $0) }
        }
    }
}

