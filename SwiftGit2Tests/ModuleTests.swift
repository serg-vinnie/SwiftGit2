
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ModuleTests: XCTestCase {
    let folder = TestFolder.git_tests.sub(folder: "ModuleTests")
    
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func test_moduleShouldNotExist() {
        (Repository.module(at: URL(fileURLWithPath: "some_shit")) | { $0.exists })
            .assertEqual(to: false, "module not exist")
    }
    
    func test_moduleShouldExists() {
        (folder.with(repo: "empty_repo", content: .empty)
            | { $0.repo }
            | { $0.asModule }
            | { $0.exists }
        ).assertEqual(to: true, "module exists")
    }
    
    func test_shouldAddAndCloneSubmodule() {
        let root = folder.sub(folder: "shouldAddSubmodule")
        let repo = (root.with(repo: "main_repo", content: .empty) | { $0.repo }).shouldSucceed()!
        
        root.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed("make repo")
        
        repo.asModule
            .shouldSucceed("asModule 1")
        
        // add
        repo.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true)
            .shouldSucceed("add submodule")

        repo.asModule
            .shouldSucceed("asModule 2")

        // file .gitmodules should exist
        (repo.directoryURL | { $0.appendingPathComponent(".gitmodules").exists })
            .assertEqual(to: true, ".gitmodules exists")
        
        
        let submodule = repo.submoduleLookup(named: "SubModule").shouldSucceed()!
        XCTAssert(submodule.name == "SubModule")
        XCTAssert(submodule.path == "SubModule")
        XCTAssert(submodule.url == "../sub_repo")
        
        let opt = SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.none)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
        
        submodule.clone(options: opt)
            .shouldSucceed("clone")
        
        repo.asModule
            .shouldSucceed("asModule 3")
        
        submodule.finalize()
            .shouldSucceed("finalize")
        
        repo.asModule
            .shouldSucceed("asModule 4")
            //.map { $0.subModules.count }
            //.assertEqual(to: 1, "sub-modules count")
    }

//    func testPerformanceExample() throws {
//        self.measure {
//
//        }
//    }
}
