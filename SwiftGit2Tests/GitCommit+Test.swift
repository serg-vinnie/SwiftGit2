import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitCommitTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitCommitTests")
    
    func test_revert() {
        let src = root.with(repo: "revert", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        let commitToRevert = (src.repo | { $0.t_commit(file: .fileA, with: .content2, msg: "2") }).shouldSucceed()!
        _ = (src.repo | { $0.t_commit(file: .fileA, with: .content3, msg: "3") }).shouldSucceed()!
        
        let gitCommit = GitCommit(repoID: repoID)
        
        gitCommit.revert(commit: commitToRevert).shouldSucceed()
    }
}
