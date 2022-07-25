import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class FileChangesTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "FileChangesTests")
    
    func test_changes() {
        let folder = root.sub(folder: "Changes")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))).repo.shouldSucceed("repo1 clone")!
        
        let filePath = "fileA.txt"
        
        let allCommitsR = repo1.commitsFromHead()
        
        _ = allCommitsR.shouldSucceed("allCommitsR found")!
        
        let diffsR = allCommitsR.flatMap{ allCommits in
            allCommits.map { commit in
                repo1.deltas(target: .commit(commit.oid))
            }
            .flatMap{ $0 }
            .map { $0.map { $0.deltasWithHunks } }
        }
        .map{ $0.map{ $0.filter { $0.newFile?.path == filePath || $0.oldFile?.path == filePath  } } }
        
        _ = diffsR.shouldSucceed("diffsR found")!
        
        
        let changedsOfFileR = combine(allCommitsR, diffsR).map { commits, diffs -> Zip2Sequence<[Commit], [[Diff.Delta]]> in
            zip(commits, diffs)
        }
        .map{ $0.filter{ $0.1.count > 0 } }
        
        let changedsOfFile = changedsOfFileR.shouldSucceed("changedsOfFileR found")!
        
        XCTAssertTrue(changedsOfFile.count > 100, "changedsOfFile count is > 100")
        
        print("\r\r\r\r")
        print("-----------------------------------------------")
        print("commits with file changes FOUND: \(changedsOfFile.count)")
        print("-----------------------------------------------")
        print("\r\r\r\r")
    }
    
    func test_changes2() {
        let folder = root.sub(folder: "Changes")
        
        _ = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))).repo.shouldSucceed("repo1 clone")!
        
        let filePath = "fileA.txt"
        
        let repoId = RepoID(path: "\(folder.url.path)/repo1")
        
        print(repoId.path)
        
        let a = repoId
            .getHistoryOfFile(withPath: filePath)
            .shouldSucceed("changedsOfFileR found")!
        
        XCTAssertTrue(a.count > 0, "result history item is MORE than 0 ")
        
        let b = a.first!.getFileContent()
            .shouldSucceed("changedsOfFileR found")!
        
        XCTAssertTrue(b.1.deltasWithHunks.count > 0, "result history item is MORE than 0 ")
    }
}

struct HistoryFileID {
    let repoID: RepoID
    let path: String
    let commitOid: OID
}

extension HistoryFileID {
    func getFileContent() -> R<(Commit, CommitDetails)> {
        let commit = repoID.repo
            .flatMap{ $0.commit(oid: self.commitOid) }
        
        let deltas = repoID.repo.flatMap{ $0.deltas(target: .commit(self.commitOid)) }
        
        return combine(commit, deltas)
    }
}

extension RepoID {
    func getHistoryOfFile(withPath filePath: String) -> R<[HistoryFileID]> {
        let repoID = self
        
        let allCommitsR = repoID.repo.flatMap { $0.commitsFromHead() }
        
        let diffsR = allCommitsR.flatMap { allCommits in
            allCommits.map { commit in
                repoID.repo.flatMap{ $0.deltas(target: .commit(commit.oid)) }
            }
            .flatMap{ $0 }
            .map { $0.map { $0.deltasWithHunks } }
        }
        .map{ $0.map{ $0.filter { $0.newFile?.path == filePath || $0.oldFile?.path == filePath  } } }
        
        let changedsOfFileR = combine(allCommitsR, diffsR)
            .map { commits, diffs -> Zip2Sequence<[Commit], [[Diff.Delta]]> in
                zip(commits, diffs)
            }
            .map { $0.filter{ $0.1.count > 0 } }
        
        return changedsOfFileR.map { $0.map{ HistoryFileID(repoID: repoID, path: $0.1.first?.newFile?.path ?? $0.1.first?.oldFile?.path ?? "" , commitOid: $0.0.oid ) } }
    }
}
