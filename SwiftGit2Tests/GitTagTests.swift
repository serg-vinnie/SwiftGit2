import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

final class GitTagTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "tag")
    
    func testCreate() {
        let folder = root.with(repo: "create", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        let repoID = folder.repoID
        
        let oid = (GitRefCache.from(repoID: repoID) | { $0.HEAD.asNonOptional } | { $0.referenceID.targetOID })
            .shouldSucceed()!
        
        GitTag(repoID: repoID).create(at: oid, name: "1.2.3", message: "", signature: .test, auth: .credentials(.none))
            .shouldSucceed()

        (GitRefCache.from(repoID: repoID) | { $0.tags.map { $0.referenceID } } )
            .shouldSucceed()
    }

}
