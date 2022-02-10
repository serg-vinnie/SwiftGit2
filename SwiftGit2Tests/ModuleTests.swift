
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

struct TestEnvironment {
    let work_root : URL
    
    init(project: String) {
        work_root = URL.userHome.appendingPathComponent(".git_tests").appendingPathComponent(project)
        _ = work_root.makeSureDirExist()
        if !Repository.exists(at: emptyRepoURL) {
            _ = Repository.create(at: emptyRepoURL)
        }
    }
    
    var emptyRepoURL : URL { work_root.appendingPathComponent("empty_repo") }
}





class ModuleTests: XCTestCase {
    let folder = TestFolder.git_tests.sub(folder: "ModuleTests")
    
    let testing = TestEnvironment(project: "ModuleTests")
    
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func test_moduleShouldNotExist() {
        let moduleNotExists = Repository.module(at: URL(fileURLWithPath: "some_shit")).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == false)
    }
    
    func test_moduleShouldExists() {
        let moduleNotExists = Repository.module(at: testing.emptyRepoURL).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            _ = Repository.module(at: testing.emptyRepoURL)
        }
    }
}
