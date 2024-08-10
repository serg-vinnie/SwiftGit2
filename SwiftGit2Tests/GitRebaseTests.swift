import Essentials
@testable import SwiftGit2
import Clibgit2
import XCTest
import EssentialsTesting

class GitRebaseTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitRebaseTests")
        
    func test_rebaseFastForward() {
        // create repo with intial commit
        // branch
        // commit into main
        // checkout branch
        // rebase
        
        // create repo with intial commit
        let src = root.with(repo: "fastForward", content: .commit(.fileA, .content1, "1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        // branch
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        // commit into main
        (repoID.repo | { $0.t_commit(file: .fileA, with: .content2, msg: "2", signature: .test) } )
            .shouldSucceed()
        
        let main = (repoID.HEAD | { $0.asReference })
            .shouldSucceed()!
        
        // checkout branch
        branch.checkout(options: CheckoutOptions(strategy: .Force))
            .shouldSucceed()
        
        let oids = GitRebase(repoID).head(source: main, signature: .test)
            .shouldSucceed("rebase")!
        
        XCTAssert(!oids.isEmpty)
        
        if let oid = oids.last {
            branch.set(target: oid, message: "rebase (finish): \(branch.name) onto \(oid.description)")
                .shouldSucceed("set target")!
        }
        
//        let rebaseURL = repoID.dbURL | { $0.appendingPathComponent("rebase-merge") }
//        (rebaseURL | { $0.exists })
//            .assertEqual(to: false)
//        let todoURL = rebaseURL | { $0.appendingPathComponent("git-rebase-todo") }
 
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
        
        let main = (repoID.HEAD | { $0.asReference })
            .shouldSucceed()!
        
        branch.checkout(options: CheckoutOptions())
            .shouldSucceed()
        
        // commit into branch | FileB
        (repoID.repo | { $0.t_commit(file: .fileB, with: .random, msg: "branch 1", signature: .test) })
            .shouldSucceed()

        GitRebase(repoID).head(source: main, signature: .test)
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
        
        let main = (repoID.HEAD | { $0.asReference })
            .shouldSucceed()!
        
        branch.checkout(options: CheckoutOptions())
            .shouldSucceed()
        
        // commit into branch | FileA
        (repoID.repo | { $0.t_commit(file: .fileA, with: .random, msg: "branch 1", signature: .test) })
            .shouldSucceed()
        
        GitRebase(repoID).head(source: main, signature: .test)
            .shouldSucceed("rebase")
    }
}
