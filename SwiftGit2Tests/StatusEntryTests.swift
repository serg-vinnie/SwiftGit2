import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusEntryTests: XCTestCase {
    func testBla() {
        let repo = Repository.t_randomRepo()
        _ = repo.flatMap { $0.t_write(file: .fileA, with: .random) }
        
        let options = StatusOptions(flags: [.includeUntracked, .renamesHeadToIndex])
        let status = repo.flatMap { $0.status(options: options) }
            .shouldSucceed()!
        
        let entrie = status[0]
        XCTAssert(entrie.indexToWorkDir != nil)
        XCTAssert(entrie.headToIndex == nil)
        
        XCTAssert(entrie.indexToWorkDir?.oldFile != nil)
        XCTAssert(entrie.indexToWorkDir?.newFile != nil)
        XCTAssert(entrie.indexToWorkDir?.oldFile?.path == entrie.indexToWorkDir?.newFile?.path)
        
        
    }

}
