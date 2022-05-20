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
        
        _ = src.addAllAndCommit(msg: "reverted to 1").shouldSucceed()!
        
        let currContent = File(url: src.urlOf(file: .fileA) ).getContent()
        let contentMustBe = TestFileContent.content1.rawValue
        
        XCTAssertEqual(currContent, contentMustBe)
    }
}
