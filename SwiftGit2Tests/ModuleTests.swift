
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ModuleTests: XCTestCase {
    let folder = TestFolder.git_tests.sub(folder: "ModuleTests")
    
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func test_moduleShouldNotExist() {
        let moduleNotExists = Repository.module(at: URL(fileURLWithPath: "some_shit")).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == false)
    }
    
    func test_moduleShouldExists() {
        let subFolder = folder.sub(folder: "empty_repo")
        let _ = subFolder.clearRepo
        
        let moduleNotExists = Repository.module(at: subFolder.url).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == true)
    }
    
    func test_shouldAddSubmodule() {
        let root = folder.sub(folder: "shouldAddSubmodule") //.cleared().shouldSucceed()!
        let repo = (root.with(repo: "main_repo", content: .empty) | { $0.repo }).shouldSucceed()!
        
        root.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
        
        // add
        repo.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true)
            .shouldSucceed()
        
        // file .gitmodules should exist
        (repo.directoryURL | { $0.appendingPathComponent(".gitmodules").exists })
            .assertEqual(to: true)
        
        
        let submodule = repo.submoduleLookup(named: "SubModule").shouldSucceed()!
        XCTAssert(submodule.name == "SubModule")
        XCTAssert(submodule.path == "SubModule")
        XCTAssert(submodule.url == "../sub_repo")
    }

//    func testPerformanceExample() throws {
//        self.measure {
//
//        }
//    }
}
