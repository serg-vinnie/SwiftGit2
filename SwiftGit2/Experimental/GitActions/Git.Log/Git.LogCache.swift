import Essentials
import Foundation
import OrderedCollections

public class GitLogCache {
    public let repoID: RepoID
    public var basicInfo = [OID:GitCommitBasicInfo]()
    public var deltas = [OID:CommitDeltas]()
    
    init(repoID: RepoID) {
        self.repoID = repoID
    }
}


