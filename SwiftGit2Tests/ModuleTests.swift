
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
        let root = folder.sub(folder: "shouldAddAndCloneSubmodule")
        
        let repo = (root.with(repo: "main_repo", content: .empty) | { $0.repo })
            .shouldSucceed()!
        
        root.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
        
        // ADD
        repo.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true)
            .shouldSucceed()

        (repo.directoryURL | { $0.appendingPathComponent(".gitmodules").exists }) // file .gitmodules should exist
            .assertEqual(to: true)

        let submodule = repo.submoduleLookup(named: "SubModule").shouldSucceed()!
        XCTAssert(submodule.name == "SubModule")
        XCTAssert(submodule.path == "SubModule")
        XCTAssert(submodule.url == "../sub_repo")
        
        // CLONE
        let opt = SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.none)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
        
        submodule.clone(options: opt)
            .shouldSucceed()
                
        // FINALIZE
        submodule.finalize()
            .shouldSucceed()
    }

    func testPerformanceExample() throws {
        self.measure {
//            Repository.at(url: URL.userHome.appendingPathComponent("dev/taogit"))
//                .flatMap { $0.asModule }
//                .shouldSucceed()
        }
    }
}
