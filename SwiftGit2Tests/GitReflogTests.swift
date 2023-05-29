
import XCTest
@testable import SwiftGit2
import Essentials
import EssentialsTesting

final class GitReflogTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "Reflog")

    func testReflog() {
        let repoID = RepoID(path: "/Users/loki/dev/a")
        GitReflog(repoID: repoID)
            .entryCount
            .shouldSucceed("entry count")
    }
}
