import Foundation
import Essentials

public struct HistoryFileID {
    public let repoID: RepoID
    public let path: String
    public let commitOid: OID
}

public extension HistoryFileID {
    func getFileContent() -> R<(Commit, CommitDetails)> {
        let commit = repoID.repo
            .flatMap{ $0.commit(oid: self.commitOid) }
        
        let deltas = repoID.repo.flatMap{ $0.deltas(target: .commit(self.commitOid)) }
        
        return combine(commit, deltas)
    }
}

public extension RepoID {
    func getHistoryOfFile(withPath filePath: String, getFirst10: Bool = true) -> R<[HistoryFileID]> {
        let repoID = self
        
        var allCommitsR: Result<[Commit], Error>
        
        if getFirst10 {
            allCommitsR = repoID.repo.flatMap { $0.commitsFromHead(num: 100) }
        } else {
            allCommitsR = repoID.repo.flatMap { $0.commitsFromHead() }
        }
        
        let diffsR = allCommitsR.flatMap { allCommits in
            allCommits.map { commit in
                repoID.repo.flatMap{ $0.deltas(target: .commit(commit.oid)) }
            }
            .flatMap{ $0 }
            .map { $0.map { $0.deltasWithHunks } }
        }
        .map{ $0.map{ $0.filter { $0.newFile?.path == filePath || $0.oldFile?.path == filePath  } } }
        
        let changesOfFileR = combine(allCommitsR, diffsR)
            .map { commits, diffs -> Zip2Sequence<[Commit], [[Diff.Delta]]> in
                zip(commits, diffs)
            }
            .map { $0.filter{ $0.1.count > 0 } }
        
        return changesOfFileR.map { $0.map{ HistoryFileID(repoID: repoID, path: $0.1.first?.newFile?.path ?? $0.1.first?.oldFile?.path ?? "" , commitOid: $0.0.oid ) } }
            .map {
                getFirst10 ? Array.init($0.first(10)) : $0
            }
    }
}
