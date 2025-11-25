import Essentials
@testable import SwiftGit2
import XCTest
import EssentialsTesting

class GitCommitTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitCommitTests")
    
    func test_revert() {
        let src = root.with(repo: "revert", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        let gitCommit = GitCommit(repoID: repoID)
        
        let commitToRevert = src.commit(file: .fileA, with: .content2, msg: "2").shouldSucceed()!.commit.shouldSucceed()!
        
        gitCommit.revert(commit: commitToRevert).shouldSucceed()
        
        _ = src.addAllAndCommit(msg: "commit 2 is reverted").shouldSucceed()!
        
        let currContent = File(url: src.urlOf(file: .fileA) ).getContent()
        let contentMustBe = TestFileContent.content1.rawValue
        
        XCTAssertEqual(currContent, contentMustBe)
    }
    
    func test_revertConflict() {
        let src = root.with(repo: "test_revertConflict", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        let gitCommit = GitCommit(repoID: repoID)
        
        let commitToRevert = src.commit(file: .fileA, with: .content2, msg: "2").shouldSucceed()!.commit.shouldSucceed()!
        _ = src.commit(file: .fileA, with: .content3, msg: "3").shouldSucceed()!
        
        _ = gitCommit.revert(commit: commitToRevert).shouldSucceed()
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
    }
    
    func test_getLastCommitsOfUser() {
        let src = root.with(repo: "test_getLastCommitsOfUser", content: .commit(.fileA, .content1, "initial")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        let gitCommit = GitCommit(repoID: repoID)
        
        let sign1 = Signature(name: "Fuuuuuu", email: "yepytrahil@gmail.com")
        let sign2 = Signature(name: "Baaarrr", email: "dusia@gmail.com")
        
        let _ = src.commit(file: .fileA, with: .content2, msg: "01", signature: sign1).shouldSucceed()!
        
        let arr1 = gitCommit.getLastCommitsDescrForUser(name: "Fuuuuuu", email: "yepytrahil@gmail.com").shouldSucceed()!
        XCTAssertEqual(arr1.count, 1)
        XCTAssertTrue(arr1.contains("01"))
        
        let _ = src.commit(file: .fileA, with: .content3, msg: "02", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "03", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "04", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "05", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "06", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "07", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "08", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "09", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "10", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "11", signature: sign1).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "12", signature: sign1).shouldSucceed()!
        
        let _ = src.commit(file: .fileA, with: .content3, msg: "13", signature: sign2).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "14", signature: sign2).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "15", signature: sign2).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "16", signature: sign2).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "17", signature: sign2).shouldSucceed()!
        
        let arr2 = gitCommit.getLastCommitsDescrForUser(name: "Fuuuuuu", email: "yepytrahil@gmail.com").shouldSucceed()!
        
        XCTAssertEqual(arr2.count, 10)
        
        XCTAssertTrue(arr2.contains("12"))
        XCTAssertTrue(arr2.contains("03"))
        XCTAssertFalse(arr2.contains("13"))
        XCTAssertFalse(arr2.contains("01"))
    }
}
