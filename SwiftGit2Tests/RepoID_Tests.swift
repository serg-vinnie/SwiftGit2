import Essentials
import SwiftGit2
import XCTest
import EssetialTesting

final class RepoID_Tests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "RepoID_Tests")
    
    func test_HEAD() {
        let repoID = root.with(repo: "head", content: .commit(.fileA, .content1, "1")).shouldSucceed()!.repoID
        
        // ReferenceID(repoID: RepoID /Users/loki/.git_tests/GitRebaseTests/head, name: "refs/heads/main")
        let oid_1 = (repoID.HEAD | { $0.asReference } | { $0.targetOID })
            .shouldSucceed()!
            
        (repoID.repo | { $0.detachHEAD() })
            .shouldSucceed("detachHEAD")
        
        // ReferenceID(repoID: RepoID /Users/loki/.git_tests/GitRebaseTests/head, name: "HEAD")
        let oid_2 = (repoID.HEAD | { $0.asReference } | { $0.targetOID })
            .shouldSucceed()!
            
        XCTAssertEqual(oid_1, oid_2)
    }
}
