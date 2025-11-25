import XCTest
import EssentialsTesting
import SwiftGit2

public class TestContainer {
    static var counter = 0
    static var inits = 0
    static var deinits = 0
    let repoID: RepoID
    let id: String?
    let tree  : RepoID.Tree<RepoID>
    init(repoID: RepoID, id: String? = nil) {
        self.repoID = repoID
        self.id = id
        self.tree = .init(repoID)
        TestContainer.counter += 1
        TestContainer.inits += 1
        print("INIT.TestContainer\(id ?? "") \(repoID)")
    }
    deinit {
        TestContainer.counter -= 1
        TestContainer.deinits += 1
        //print("DE-INIT.TestContainer\(id ?? "") \(repoID)")
    }
}

class RepCoreTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "RepCoreTests")

    func test_shoudAppendRootRepo() {
        let folder = root.sub(folder: "AppendRootRepo").cleared().shouldSucceed()!
        
        folder.with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
            .flatMap { $0.with(submodule: "sub_repo", content: .commit(.fileB, .random, "initial commit")) }
            .shouldSucceed("addSub")

        let repoID = RepoID(url: folder.sub(folder: "main_repo").url)
        
        var repCore = RepCore<TestContainer>.empty.appendingRoot(repoID: repoID, block: { TestContainer(repoID: $0) })
            .shouldSucceed("RepCore")!
        
        XCTAssert(TestContainer.counter == 2)
        
        repCore = repCore.removingRoot(repoID: repoID)
        
        XCTAssert(TestContainer.counter == 0)
    }

}
