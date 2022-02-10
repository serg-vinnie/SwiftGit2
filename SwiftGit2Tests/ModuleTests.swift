
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
        let sub_folder = folder.sub(folder: "empty_repo")
        let _ = sub_folder.cleared() | { $0.repoCreate }
        
        let moduleNotExists = Repository.module(at: sub_folder.url).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == true)
    }

//    func testPerformanceExample() throws {
//        self.measure {
//
//        }
//    }
}
