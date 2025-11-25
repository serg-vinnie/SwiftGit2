import XCTest
@testable import SwiftGit2
import Essentials
import EssentialsTesting


class GitLogTests: XCTestCase {
//    let root = TestFolder.git_tests.sub(folder: "FileChangesTests")
    let root = TestFolder.git_tests.sub(folder: "FileHistory")
    
    func test_historyStep_1commit() {
        let folder = root.with(repo: "historyStep1", content: .commit(.fileA, .content1, "initial commit"), cleared: true).shouldSucceed()!
        let repoID = folder.repoID
        let mainRefID = ReferenceID(repoID: repoID, name: "refs/heads/main")
        let commits = GitLog(refID: mainRefID).commitIDs
            .shouldSucceed()!
        
        let commitID = commits.first!
        let treeID = commitID.treeID
        let blobID = treeID | { $0.blob(name: TestFile.fileA.rawValue) }
        let fileID = blobID | { GitFileID(path: TestFile.fileA.rawValue, blobID: $0, commitID: commitID) }
        
        (fileID | { $0.historyStep() })
            .map { $0.files.count }
            .assertEqual(to: 1)
    }
    
    func test_historyStep_1commit_shorter() {
        let folder = root.with(repo: "historyStep1", content: .commit(.fileA, .content1, "initial commit"), cleared: true).shouldSucceed()!
        let fileID = folder.repoID.mainRefID.t_recentFileID(name: TestFile.fileA.rawValue)
        
        (fileID | { $0.historyStep() })
            .map { $0.files.count }
            .assertEqual(to: 1)
        
        //------------------------------
        (fileID | { $0.log })
            .map { $0.files.count }
            .assertEqual(to: 1)
    }
    
    func test_historyStep_2commitsAB() {
        let folder = root.with(repo: "historyStep1", content: .commit(.fileA, .content1, "initial commit"), cleared: true).shouldSucceed()!
        folder.commit(file: .fileB, msg: "commit2")
            .shouldSucceed()
        
        let fileID = folder.repoID.mainRefID.t_recentFileID(name: TestFile.fileA.rawValue)
        
        (fileID | { $0.historyStep() })
            .map { $0.files.count }
            .assertEqual(to: 2)
        
        //------------------------------
        (fileID | { $0.log })
            .map { $0.files.count }
            .assertEqual(to: 2)
    }
    
    func test_historyStep_ABAA() {
        let repoID = root.repo(name: "historyStep_ABAA", commits: [[.randomA], [.randomB], [.randomA], [.randomA]], cleared: true).shouldSucceed()!
        let fileID_A = repoID.mainRefID.t_recentFileID_A
        let fileID_B = repoID.mainRefID.t_recentFileID_B
        
        repoID.mainRefID.t_log()
            .shouldSucceed("log")
            
        (fileID_A | { $0.historyStep() })
            .map { $0.files.count }
            .assertEqual(to: 1, "A")
        
        (fileID_B | { $0.historyStep() })
            .map { $0.files.count }
            .assertEqual(to: 3, "B")
        
        //------------------------------
        (fileID_A | { $0.log })
            .map { $0.files.count }
            .assertEqual(to: 4, "A")
        
        (fileID_B | { $0.log })
            .map { $0.files.count }
            .assertEqual(to: 3, "B")
    }
    
    func test_historyStep_rename() {
        let file = TestCustomFile.randomA
//        let repoID = root.repo(name: "historyStep_rename", commits: [[file], [file.renamed(path: "folder/fileB.txt"), .removeA]], cleared: true).shouldSucceed()!
        let repoID = root.repo(name: "historyStep_rename", commits: [[file], [file.renamed(path: "fileB.txt"), .removeA]], cleared: true).shouldSucceed()!
        repoID.mainRefID.t_log()
            .shouldSucceed("log")
        
        let fileID_A = repoID.mainRefID.t_recentFileID_A
        let fileID_B = repoID.mainRefID.t_recentFileID_B
        

        //------------------------------
        (fileID_A | { $0.log })
            .shouldFail("A")
        
        (fileID_B | { $0.log })
            .map { $0.files.count }
            .assertEqual(to: 2, "B")
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
}

extension ReferenceID {
    var t_recentFileID_A :  R<GitFileID> { t_recentFileID(name: TestFile.fileA.rawValue) }
    var t_recentFileID_B :  R<GitFileID> { t_recentFileID(name: TestFile.fileB.rawValue) }
    
    func t_recentFileID(name: String) -> R<GitFileID> {
        let commits = GitLog(refID: self).commitIDs
        let commitID = commits | { $0.first.asNonOptional("firstCommit for recent file") }
        let treeID = commitID | { $0.treeID }
        let blobID = treeID | { $0.blob(name: name) }
        return combine(blobID,commitID) | { GitFileID(path: name, blobID: $0, commitID: $1) }
    }
    
    func t_log() -> R<[String]> {
        GitLog(refID: self).commitIDs | { $0.flatMap { c in c.summary | { $0 + ":" + c.oid.oidShort } } }
    }
}
