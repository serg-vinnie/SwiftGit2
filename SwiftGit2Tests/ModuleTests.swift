
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ModuleTests: XCTestCase {
    override func setUpWithError()    throws {} // Put setup code here. This method is called before the invocation of each test method in the class.
    override func tearDownWithError() throws {} // Put teardown code here. This method is called after the invocation of each test method in the class.

    func testExample() {
        let url = URL(fileURLWithPath: "/Users/loki/dev/taogit")
        
        self.measure {
            let children = Repository.at(url: url) | { $0.childrenURLs }
            let urls = children.shouldSucceed()
            print(urls)
        }        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
