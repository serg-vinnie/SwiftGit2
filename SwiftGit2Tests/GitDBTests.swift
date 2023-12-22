
import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

final class GitDBTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "db")

    func test_extract() {
        let folder = root.with(repo: "objects", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        let subUrl = folder.url.appendingPathComponent("subFolder")
        _ = subUrl.makeSureDirExist()
        _ = subUrl.appendingPathComponent("fileB.txt").write(string: "bla-bla-bla")
        folder.addAllAndCommit(msg: "second commit")
            .shouldSucceed()
        
        let extract = root.url.appendingPathComponent("objects_extract")
        extract.rm().shouldSucceed()
        extract.makeSureDirExist().shouldSucceed()
        
        GitDB(repoID: repoID).trees
            .shouldSucceed("trees").asNonOptional
            .flatMap { $0.last.asNonOptional("last tree") }
            .flatMap { $0.extract(at: extract) }
            .shouldSucceed("extract")
        

        (GitDB(repoID: repoID).trees | { $0.hierarchy })
            .map { $0.roots.keys.map { $0.oid.oidShort } }
            .shouldSucceed("root")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {

            // Put the code you want to measure the time of here.
        }
    }

}
