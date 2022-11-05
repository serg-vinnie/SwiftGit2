import Essentials
import SwiftGit2
import XCTest
import EssetialTesting

class GitRebaseTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitRebaseTests")
        
    func test_rebaseFastForward() {
        // create repo with intial commit
        // branch
        // commit into main
        // checkout branch
        // rebase
        
        let src = root.with(repo: "fastForward", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        (repoID.repo | { $0.t_commit(file: .fileA, with: .content2, msg: "2", signature: .test) } )
            .shouldSucceed()
        
        let main = repoID.HEAD
            .shouldSucceed()!.asReference
        
        branch.checkout()
            .shouldSucceed()
        
        GitRebase(repoID).head(from: main, sigature: .test)
            .shouldSucceed("rebase")
    }
    
    func test_rebaseNormal() {
        // create intial commit
        // branch
        // commit fileA         <--
        // checkout branch
        // commit fileB         <--
        // rebase
        
        let src = root.with(repo: "normal", content: .commit(.fileA, .content1, "main 1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        // commit 2 into main
        (repoID.repo | { $0.t_commit(file: .fileA, with: .random, msg: "main 2", signature: .test) })
            .shouldSucceed()
        
        let main = repoID.HEAD
            .shouldSucceed()!.asReference
        
        branch.checkout()
            .shouldSucceed()
        
        // commit into branch | FileB
        (repoID.repo | { $0.t_commit(file: .fileB, with: .random, msg: "branch 1", signature: .test) })
            .shouldSucceed()

        GitRebase(repoID).head(from: main, sigature: .test)
            .shouldSucceed("rebase")
    }
    
    func test_rebaseConflict() {
        // create intial commit
        // branch
        // commit fileA         <--
        // checkout branch
        // commit fileB         <--
        // rebase
        
        let src = root.with(repo: "normal", content: .commit(.fileA, .random, "main 1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        // commit 2 into main | FileA
        (repoID.repo | { $0.t_commit(file: .fileA, with: .random, msg: "main 2", signature: .test) })
            .shouldSucceed()
        
        let main = repoID.HEAD
            .shouldSucceed()!.asReference
        
        branch.checkout()
            .shouldSucceed()
        
        // commit into branch | FileA
        (repoID.repo | { $0.t_commit(file: .fileA, with: .random, msg: "branch 1", signature: .test) })
            .shouldSucceed()
        
        GitRebase(repoID).head(from: main, sigature: .test)
            .shouldSucceed("rebase")
    }
}
