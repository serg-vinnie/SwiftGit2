
import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

extension RepoID : TreeStorageAgent {
    public var storageFactory: TestContainer { TestContainer(repoID: self) }
    public var rootStorageFactory: TestContainer { TestContainer(repoID: self, id: "_root") }
}

final class CacheStorageTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "CacheTests")
    
    func test_taogit() {
        let repoID = RepoID(path: "/Users/loki/dev/taogit")
        let storage = CacheStorage<RepoID>()
        storage.update(root: repoID)
        XCTAssertEqual(storage.roots.count, 1)
        XCTAssertEqual(storage.items.count, 9)
        
        let tree = storage.roots.first!.value.tree
        
        let all = tree.items.sorted { $0.url.pathComponents.count < $1.url.pathComponents.count }
        for item in all {
            let children = tree.childrenOf[item] ?? []
            let allChildren = tree.allChildrenOf[item] ?? []
            let parents = tree.parentsOf[item] ?? []
            //let allParents = tree.
            print("- [\(children.count) - \(allChildren.count)] [\(parents.count)] - \(item)")
        }
        
        do {
            let sub = RepoID(path: repoID.path + "/SwiftGit2/Carthage/Checkouts/Quick/Externals/Nimble")
            let parents = tree.parentsOf[sub] ?? []
            print("\n* parents of \(sub)")
            for item in parents {
                print("** \(item)")
            }
        }
        
        do {
            let sub = RepoID(path: repoID.path + "/AppCore")
            let parents = tree.parentsOf[sub] ?? []
            print("\n# parents of \(sub)")
            for item in parents {
                print("## \(item)")
            }
        }
        
//        do {
//            print("all chlidren of \(repoID)")
//            for item in tree.allChildrenOf[repoID]! {
//                print("* \(item)")
//            }
//        }
        
        //rootStorage.
    }
    
    func test_simple() {
        TestContainer.counter = 0
        TestContainer.deinits = 0
        
        let folder = root.with(repo: "simple", content: .empty).shouldSucceed()!
        let repoID = folder.repoID
        let storage = CacheStorage<RepoID>()
        storage.update(root: repoID)
        XCTAssertEqual(storage.roots.count, 1)
        XCTAssertEqual(storage.items.count, 1)
        XCTAssertEqual(TestContainer.counter, 2)
        XCTAssertEqual(TestContainer.deinits, 0)
        
        let sub = folder.with(submodule: "sub_repo",  content: .commit(.fileB, .random, "initial commit"))
            .shouldSucceed()!
        
        storage.update(root: repoID)
        storage.update(root: repoID)
        
        XCTAssertEqual(storage.roots.count, 1)
        XCTAssertEqual(storage.items.count, 2)
        XCTAssertEqual(TestContainer.counter, 3)
        XCTAssertEqual(TestContainer.deinits, 0)
        
        
        (sub.repoID.module | { $0.submoduleIDs.first } | { $0.asNonOptional } | { $0.remove() })
            .shouldSucceed()
        
        storage.update(root: repoID)
        storage.update(root: repoID)
        XCTAssertEqual(storage.roots.count, 1)
        XCTAssertEqual(storage.items.count, 1)
        XCTAssertEqual(TestContainer.counter, 2)
        XCTAssertEqual(TestContainer.deinits, 1)
    }
    
    func test_refCache() {
        let repoID = RepoID(path: "/Users/loki/dev/taogit")
        _ = GitRefCache.from(repoID: repoID)
        measure {
            _ = GitRefCache.from(repoID: repoID)
        }
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
