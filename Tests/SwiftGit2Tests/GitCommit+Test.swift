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
        let contentMustBe = TestFileContent.content1.content
        
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
        let emailDusia = "dusia@gmail.com"
        let emailPaul = "paul@gmail.com"
        
        let src = root.with(repo: "test_getLastCommitsOfUser", content: .commit(.fileA, .content1, "initial")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        let gitCommit = GitCommit(repoID: repoID)
        
        let signPaul = Signature(name: "Fuuuuuu", email: emailPaul)
        let signDusia = Signature(name: "Baaarrr", email: emailDusia)
        
        let _ = src.commit(file: .fileA, with: .content2, msg: "01", signature: signPaul).shouldSucceed()!
        
        let arr1 = gitCommit.getLastCommitsDescrForUser(name: "Fuuuuuu", email: emailPaul).shouldSucceed()!
        XCTAssertEqual(arr1.count, 1)
        XCTAssertTrue(arr1.contains("01"))
        
        let _ = src.commit(file: .fileA, with: .content3, msg: "02", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "03", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "04", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "05", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "06", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "07", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "08", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "09", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "10", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "11", signature: signPaul).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "12", signature: signPaul).shouldSucceed()!
        
        let _ = src.commit(file: .fileA, with: .content3, msg: "13", signature: signDusia).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "14", signature: signDusia).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "15", signature: signDusia).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content2, msg: "16", signature: signDusia).shouldSucceed()!
        let _ = src.commit(file: .fileA, with: .content3, msg: "17", signature: signDusia).shouldSucceed()!
        
        // must be 03-12
        let arr2 = gitCommit.getLastCommitsDescrForUser(name: "Fuuuuuu", email: emailPaul, count: 10).shouldSucceed()!
        
        XCTAssertEqual(arr2.count, 10)
        
        XCTAssertTrue(arr2.contains("03"))
        XCTAssertTrue(arr2.contains("12"))
        XCTAssertFalse(arr2.contains("01"))
        XCTAssertFalse(arr2.contains("13"))
    }
}
