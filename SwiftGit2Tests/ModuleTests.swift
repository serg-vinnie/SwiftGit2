
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

struct TestsRepoConfig {
    let work_root = URL.userHome.appendingPathComponent(".git_tests/SwiftGit2")
    
    init() {
        _ = work_root.makeSureDirExist()
    }
    
    var invalidURL : URL { URL(fileURLWithPath: "some_shit") }
}

fileprivate let url = URL(fileURLWithPath: "/Users/loki/dev/taogit")
fileprivate let url_bad = URL(fileURLWithPath: "/Users/loki/dev/taogit_bbbbbb")

fileprivate let work_dir = URL.userHome.appendingPathComponent(".git_tests")

class ModuleTests: XCTestCase {
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func test_moduleShouldNotExist() {
        let moduleNotExists = Repository.module(at: TestsRepoConfig().invalidURL).shouldSucceed()!
        XCTAssert(moduleNotExists.exists == false)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            _ = Repository.module(at: url)
        }
    }
}
