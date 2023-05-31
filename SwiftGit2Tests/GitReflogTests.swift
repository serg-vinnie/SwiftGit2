
import XCTest
@testable import SwiftGit2
import Essentials
import EssentialsTesting

final class GitReflogTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "Reflog")

    func test_shouldReadReflog() {
        let folder = root.with(repo: "read_reflog", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        (GitReflog(repoID: repoID).iterator | { $0[0] } )
            .shouldSucceed("first entry")
    }
    
    func test_shouldParse() {
        let folder = root.with(repo: "parse", content: .clone(.testRepoSSH, .defaultSSH)).shouldSucceed()!
        let repoID = folder.repoID
        
        let cloneEntry = (GitReflog(repoID: repoID).iterator | { $0[0] } )
        
        (cloneEntry | { $0.kind })
            .assertEqual(to: .clone(URL.testRepoSSH.path), "kind == clone")
        
        folder.commit(msg: "quick and dirty commit")
            .shouldSucceed()
        
        (GitReflog(repoID: repoID).iterator | { $0[0].kind } )
            .assertEqual(to: .commit("quick and dirty commit"), "kind == commit")
        
        
        let oid = cloneEntry | { $0.newOID }
        let repo = repoID.repo
        (combine(repo, oid) | { repo, oid in repo.checkout(oid, options: .init()) })
            .shouldSucceed()
        
        (GitReflog(repoID: repoID).iterator | { $0[0].kind } )
            .assertEqual(to: .checkout(.branch("master"), .commit(oid.maybeSuccess!)), "kind == checkout")
    }
}
