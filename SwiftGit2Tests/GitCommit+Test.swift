import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitCommitTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitCommitTests")
    
    func test_revert() {
        let src = root.with(repo: "revert", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        let gitCommit = GitCommit(repoID: repoID)
        
        let commitToRevert = src.commit(file: .fileA, with: .content2, msg: "2").shouldSucceed()!
        
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
        
        let commitToRevert = src.commit(file: .fileA, with: .content2, msg: "2").shouldSucceed()!
        _ = src.commit(file: .fileA, with: .content3, msg: "3").shouldSucceed()!
        
        _ = gitCommit.revert(commit: commitToRevert).shouldSucceed()
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
    }
}
