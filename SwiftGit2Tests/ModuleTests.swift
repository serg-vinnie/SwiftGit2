
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

struct TestsRepoConfig {
    let work_root : URL
    
    init(project: String) {
        work_root = URL.userHome.appendingPathComponent(".git_tests").appendingPathComponent(project)
        _ = work_root.makeSureDirExist()
        if !Repository.exists(at: emptyRepoURL) {
            _ = Repository.create(at: emptyRepoURL)
        }
    }
    
    var invalidURL : URL { URL(fileURLWithPath: "some_shit") }
    var emptyRepoURL : URL { work_root.appendingPathComponent("empty_repo") }
}

let swiftGit2Config = TestsRepoConfig(project: "SwiftGit2")

class ModuleTests: XCTestCase {
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func test_moduleShouldNotExist() {
        let moduleNotExists = Repository.module(at: swiftGit2Config.invalidURL).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == false)
    }
    
    func test_moduleShouldExists() {
        let moduleNotExists = Repository.module(at: swiftGit2Config.emptyRepoURL).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            _ = Repository.module(at: swiftGit2Config.emptyRepoURL)
        }
    }
}
