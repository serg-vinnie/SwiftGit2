import Essentials
import SwiftGit2
import XCTest
import EssetialTesting

class GitRebaseTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitRebaseTests")
    
    func test_rebaseFastForward() {
        let src = root.with(repo: "fastForward", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        let repo   = repoID.repo.shouldSucceed()!
        
        let ref = GitBranches(repoID).new(from: .HEAD, name: "branch", checkout: false)
            .shouldSucceed()!
        
        repo.t_commit(file: .fileA, with: .content2, msg: "2", signature: .test)
            .shouldSucceed()
        
        let main = GitBranches(repoID).HEAD
            .shouldSucceed()!
        
        ref.checkout()
            .shouldSucceed()
        
        GitRebase(repoID).head(from: main, sigature: .test)
            .shouldSucceed("rebase")
    }
    
    func test_rebaseNormal() {
        
    }
    
    func test_rebaseConflict() {
        
    }
}
