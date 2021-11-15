import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusEntryTests: XCTestCase {
    func testBla() {
        GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .shouldSucceed()
    }

}
