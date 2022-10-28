import Essentials
import Foundation
import OrderedCollections


/// WIP concept

public struct GitCommitInfo {
    let id : CommitID
}

public class GitCommitCache {
    let repoID: RepoID
    var cache = [OID:GitCommitInfo]()
    
    init(repoID: RepoID) {
        self.repoID = repoID
    }
    
    func info(oid: OID) -> R<GitCommitInfo> {
        if let inf = cache[oid] {
            return .success(inf)
        }
        
        return CommitID(repoID: repoID, oid: oid).info
            .onSuccess { self.cache[oid] = $0 }
    }
}


