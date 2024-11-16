import XCTest
@testable import SwiftGit2
import Essentials
import EssentialsTesting

class GitLogTests: XCTestCase {
//    let root = TestFolder.git_tests.sub(folder: "FileChangesTests")
    let root = TestFolder.git_tests.sub(folder: "FileHistory")
    
    func test_historyStep1() {
        let folder = root.with(repo: "historyStep1", content: .commit(.fileA, .content1, "initial commit"), cleared: false).shouldSucceed()!
        let repoID = folder.repoID
        let mainRefID = ReferenceID(repoID: repoID, name: "refs/heads/main")
        var commits = GitLog(refID: mainRefID).commitIDs
            .shouldSucceed("log")!
        
        let commitID = commits.first!
        let treeID = commitID.treeID
        let blobID = treeID | { $0.blob(name: TestFile.fileA.rawValue) }
        let fileID = blobID | { GitFileID(path: TestFile.fileA.rawValue, blobID: $0, commitID: commitID) }
        
        (fileID | { $0.historyStep() })
            .shouldSucceed("historyStep")
    }
    
    func test_fileWalk() {
        // file A [1]
        let folder = root.with(repo: "fileWalk", content: .commit(.fileA, .content1, "initial commit"), cleared: false).shouldSucceed()!
        let repoID = folder.repoID
        print(repoID)
        let mainRefID = ReferenceID(repoID: repoID, name: "refs/heads/main")
        var commits = GitLog(refID: mainRefID).commitIDs
            .shouldSucceed("log")!
        
        if commits.count < 4 {
            folder.commit(file: .fileA, with: .random, msg: "commit 22").shouldSucceed()
            folder.commit(file: .fileB, with: .content2, msg: "commit 2").shouldSucceed()
            folder.commit(file: .fileB, with: .content3, msg: "commit 3").shouldSucceed()
            folder.commit(file: .fileA, with: .content4, msg: "commit 4").shouldSucceed()
            
            commits = GitLog(refID: mainRefID).commitIDs
                .shouldSucceed("log again")!
        }
        print("log: ",commits.map { $0.oid.oidShort })

        let commitID4 = commits.first!
        let treeID4 = commitID4.treeID

        let blobIDb4 = treeID4 | { $0.blob(name: TestFile.fileB.rawValue) }
        
        let fileIDb = blobIDb4 | { GitFileID(path: TestFile.fileB.rawValue, blobID: $0, commitID: commitID4) }
        blobIDb4.shouldSucceed("BlobB4")
                
//        (fileIDb | { $0.walk() })
//            .shouldSucceed("B")
        
        (fileIDb | { $0.historyStep() })
            .shouldSucceed("B")
        
        
        
        
        //        let treeID2 = headCommitID2.treeID
//        let blobID2 = treeID2 | { $0.blob(name: TestFile.fileA.rawValue) }
//        let fileID2 = blobID2 | { GitFileID(path: TestFile.fileA.rawValue, blobID: $0, commitID: headCommitID2) }
//        
//        (fileID2 | { $0.walk() })
//            .shouldSucceed("parents")
        
//        let fileID = headCommitID.matchFile(path: TestFile.fileA.rawValue)
//            .shouldSucceed()!
        
//        XCTAssertEqual(fileID.path, TestFile.fileA.rawValue)
//        XCTAssertEqual(fileID.commitID, headCommitID)
    }
    
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
        
        XCTAssertTrue(b.details.all.count > 0, "result history item is MORE than 0 ")
    }
}
