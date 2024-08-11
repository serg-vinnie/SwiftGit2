import Essentials
@testable import SwiftGit2
import Clibgit2
import XCTest
import EssentialsTesting

extension git_rebase_operation_t : CustomStringConvertible {
    public var description: String {
        switch self {
        case GIT_REBASE_OPERATION_PICK:     return "pick"
        case GIT_REBASE_OPERATION_REWORD:   return "reword"
        case GIT_REBASE_OPERATION_EDIT:     return "edit"
        case GIT_REBASE_OPERATION_SQUASH:   return "squash"
        case GIT_REBASE_OPERATION_FIXUP:    return "fixup"
        case GIT_REBASE_OPERATION_EXEC:     return "exec"
        default: return "rawValue: \(self.rawValue)"
        }
    }
}

extension git_rebase_operation : CustomStringConvertible {
    public var description: String {
        return "Rebase Operation: \(type) \(OID(id).oidShort) " + self.exec.asSwiftString
    }
}

class GitRebaseTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitRebaseTests")
    
    func test_lowLevel() {
        let src = root.with(repo: "lowLevel", content: .commit(.fileA, .content1, "commit 1 on main")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        // branch
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        let main = (repoID.HEAD | { $0.asReference })
            .shouldSucceed()!
        
        repoID.t_commit(file: .fileA, with: .content2, msg: "commit 2 on main", signature: .test)
            .map { $0.oid.oidShort }
            .shouldSucceed("commit 2 on main")
        
        branch.checkout(options: CheckoutOptions(strategy: .Force))
            .shouldSucceed("checkout branch")
        
        repoID.t_commit(file: .fileA, with: .content3, msg: "commit 2 on branch", signature: .test)
            .map { $0.oid.oidShort }
            .shouldSucceed("commit 2 on branch")
        
//        repoID.t_commit(file: .fileA, with: .content2, msg: "commit 3 on main", signature: .test)
//            .map { $0.oid.oidShort }
//            .shouldSucceed("commit 3")
        
        let options = RebaseOptions()
        let repo = repoID.repo.maybeSuccess!
        var operation : UnsafeMutablePointer<git_rebase_operation>?
        
        let src_ac = main.annotatedCommit
        let dst_ac = branch.annotatedCommit
        
        let rebase = (combine(src_ac, dst_ac) | { src, dst in repo.rebase(branch: src, upstream: dst, onto: nil, options: options) })
            .shouldSucceed("rebase")!
        
        
        print("operations count \(rebase.operationsCount)")
        
        rebase.next(operation: &operation)
            .shouldSucceed("next 1")
        
        print(operation!.pointee)
        
        repo.stage(.all)
            .shouldSucceed("stage all")
        
        rebase.commit(signature: .test).map { $0.oidShort }
            .shouldSucceed("commit 1")
        
        rebase.next(operation: &operation)
            .shouldSucceed("next 2")
        print(operation!.pointee)
        
        rebase.commit(signature: .test).map { $0.oidShort }
            .shouldSucceed("commit 2")
    }
    
    func test_rebaseFastForward() {
        // create repo with intial commit
        // branch
        // commit into main
        // checkout branch
        // rebase
        
        // create repo with intial commit
        let src = root.with(repo: "fastForward", content: .commit(.fileA, .content1, "commit 1")).shouldSucceed()!
        let repoID = RepoID(url: src.url)
        
        // branch
        let branch = GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()!
        
        // commit into main
        (repoID.repo | { $0.t_commit(file: .fileA, with: .content2, msg: "commit 2", signature: .test) } )
            .shouldSucceed()
        
        let main = (repoID.HEAD | { $0.asReference })
            .shouldSucceed()!
        
        // rebase
        let oids = GitRebase(repoID).run(src: .ref(main), dst: branch, signature: .test)
            .shouldSucceed("rebase")!
        
        XCTAssert(!oids.isEmpty)
        
        repoID.HEAD
            .assertEqual(to: .attached(branch))
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

//        GitRebase(repoID).head(source: main, signature: .test)
//            .shouldSucceed("rebase")
        
        let oids = GitRebase(repoID).run(src: .ref(main), dst: branch, signature: .test)
            .shouldSucceed("rebase")!
        
        XCTAssert(!oids.isEmpty)
        
        repoID.HEAD
            .assertEqual(to: .attached(branch))
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
