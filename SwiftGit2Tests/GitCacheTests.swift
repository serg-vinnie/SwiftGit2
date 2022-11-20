
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

final class GitCacheTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "CacheTests")
    
    func test_simple() {
        let folder = root.sub(folder: "simple").cleared().shouldSucceed()!
    }
    
//    func test_repo_sub() {
//        let folder = root.sub(folder: "Clone").cleared().shouldSucceed()!
//        folder   .with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
//            .with(submodule: "sub_repo",  content: .commit(.fileB, .random, "initial commit"))
//            .shouldSucceed("addSub")
//    }

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
