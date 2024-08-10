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
//        branch.checkout(options: CheckoutOptions(strategy: .Force))
//            .shouldSucceed()
        
//        let rebaseURL = repoID.dbURL | { $0.appendingPathComponent("rebase-merge") }
//        (rebaseURL | { $0.exists })
//            .assertEqual(to: false)
//        let todoURL = rebaseURL | { $0.appendingPathComponent("git-rebase-todo") }
        
        // rebase
//        let rebase = GitRebase(repoID).start(onto: branch)
//            .shouldSucceed("start")!
        
        let checkoutOption = CheckoutOptions()
        
        let onto = branch
        let head = repoID.HEAD | { $0.asReference }
        let head_ac = head | { $0.annotatedCommit }
        let sync = head | { BranchSync.with(our: $0, their: onto) }
        let base = sync | { $0.base } | { CommitID(repoID: repoID, oid: $0) } | { $0.annotatedCommit }
        let repo = repoID.repo
        let _rebase = combine(repo, onto.annotatedCommit, base, head_ac)
        | { repo, onto, base, head in
             repo.rebase(branch: head /* base */ /*no head*/, upstream: onto, onto: nil, options: RebaseOptions(checkout: checkoutOption))
        }
        let rebase = _rebase.maybeSuccess!
        
//        print(rebase.operationsCount)
//        let headOID = main.targetOID
//        (combine(headOID, todoURL) | { oid, url in ("pick " + oid.description.first(7) + " 2").write(to: url) })
//            .shouldSucceed("write")
//        print(rebase.operationsCount)
        
        var operation : UnsafeMutablePointer<git_rebase_operation>? 
        rebase.next(operation: &operation)
            .shouldSucceed("next")
        
        print(operation!.pointee)
        
        rebase.commit(signature: .test)
            .shouldSucceed("commit")
        
        rebase.next(operation: &operation)
            .shouldFail("next end")
        

        
//        todoURL | { $0. }
        
        rebase.finish(signature: .test)
            .shouldSucceed("finish")
        
        (repoID.dbURL | { $0.appendingPathComponent("rebase-merge").exists })
            .assertEqual(to: false)
//        GitRebase(repoID).head(from: main, signature: .test)
//            .shouldSucceed("rebase")
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

        GitRebase(repoID).head(from: main, signature: .test)
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
        
        GitRebase(repoID).head(from: main, signature: .test)
            .shouldSucceed("rebase")
    }
}
