
import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

final class GitDBTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "db")

    func testExample() {
        let folder = root.with(repo: "oid", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        GitDB(repoID: repoID).objects.shouldSucceed("oids")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
