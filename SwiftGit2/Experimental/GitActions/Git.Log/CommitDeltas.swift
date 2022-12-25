
import Foundation
import Essentials

public struct CommitDeltas {
    public let commitID        : CommitID?
    public let parents         : [OID]
    public let deltasWithHunks : [Diff.Delta]
    public let all             : [OID:[Diff.Delta]]
    public let desc            : String
    
    public static var emtpy : CommitDeltas { CommitDeltas(commitID: nil, parents: [], deltasWithHunks: [], all: [:], desc: "")  }
    
    public func with(parent: Int) -> CommitDeltas {
        guard parents.count > 0 else { return self }
        guard parent < parents.count else {
            return CommitDeltas(commitID: commitID, parents: parents, deltasWithHunks: all.first!.value, all: all, desc: desc)
        }
        
        if let element = all[parents[parent]] {
            return CommitDeltas(commitID: commitID, parents: parents, deltasWithHunks: element, all: all, desc: desc)
        }
        return self
    }
}

public extension Repository {
    func deltas(target: CommitTarget, findOptions: Diff.FindOptions = [.renames, .renamesFromRewrites] ) -> R<CommitDeltas> {
        if headIsUnborn {
            return .success(.emtpy)
        }
        
        let commit      = target.commit(in: self)
        let commitID    = combine(self.repoID, commit) | { CommitID(repoID: $0, oid: $1.oid) }
        let desc        = commit | { $0.description }
        let commitTree  = commit | { $0.tree() }
        let parents     = commit | { $0.parents() }
        
        if case .success(let parents) = parents {
            if parents.isEmpty {
                let deltas = commitTree | { self.diffTreeToTree(oldTree: nil, newTree: $0) } | { $0.asDeltasWithHunks() }
                
                return combine(deltas, desc, commitID) | { CommitDeltas(commitID: $2, parents: [], deltasWithHunks: $0, all: [:], desc: $1) }
            }
        }
        
        let parentOIDs  = parents | { $0 | { $0.oid } }
        let parentTrees = parents | { $0 | { $0.tree() } }
        let deltas      = combine(commitTree, parentTrees) | { tree, parents in parents | {
            self.diffTreeToTree(oldTree: $0, newTree: tree)
                | { $0.findSimilar(options: findOptions) }
                | { $0.asDeltasWithHunks() } } }
        
        return combine(parentOIDs, deltas, desc, commitID) | { commitDetails(commitID: $3, parents: $0, deltas: $1, desc: $2) }
    }
    
    func commitDetails(commitID: CommitID,parents: [OID], deltas:[[Diff.Delta]], desc: String) -> R<CommitDeltas> {
        guard parents.count == deltas.count else {
            return .failure(WTF("commitDetails: parents.count == deltas.count"))
        }
        
        // exclude empty deltas from selection
        let filteredParents = parents.enumerated().filter { idx, _ in !deltas[idx].isEmpty }.map { $0.element }
        let filetredDeltas  = deltas.filter { !$0.isEmpty }
        let filteredAll     = filteredParents.asDictionary(other: filetredDeltas)
        
        if let firstDelta = filetredDeltas.first {
            return filteredAll | { CommitDeltas(commitID: commitID, parents: filteredParents, deltasWithHunks: firstDelta, all: $0, desc: desc) }
        }
        
        return .success(CommitDeltas(commitID: commitID, parents: [], deltasWithHunks: [], all: [:], desc: desc))
        
    }

}
