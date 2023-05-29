
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
}
