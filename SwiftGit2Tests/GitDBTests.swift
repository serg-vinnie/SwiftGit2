
import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

final class GitDBTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "db")

    func testExample() {
        let folder = root.with(repo: "objects", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        let subUrl = folder.url.appendingPathComponent("subFolder")
        _ = subUrl.makeSureDirExist()
        _ = subUrl.appendingPathComponent("fileB.txt").write(string: "bla-bla-bla")
        folder.addAllAndCommit(msg: "second commit")
            .shouldSucceed()
        
//        (repoID.repo | { $0.t_with_commit(file: .fileBInFolder, with: .random, msg: "second commit") })
//            .shouldSucceed()
        
        GitDB(repoID: repoID).trees
            .flatMap { $0.flatMap { $0.entries } }
            .shouldSucceed("trees")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
