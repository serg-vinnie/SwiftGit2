import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusEntryTests: XCTestCase {
    func test_bla() {
        let repo = Repository.t_randomRepo()
        _ = repo.flatMap { $0.t_write(file: .fileA, with: .random) }
        
        let status = repo.flatMap { $0.status() }
            .shouldSucceed()!
        
        let entrie = status[0]
        XCTAssert(entrie.indexToWorkDir != nil)
        XCTAssert(entrie.headToIndex == nil)
        
        XCTAssert(entrie.indexToWorkDir?.oldFile != nil)
        XCTAssert(entrie.indexToWorkDir?.newFile != nil)
        XCTAssert(entrie.indexToWorkDir?.oldFile?.path == entrie.indexToWorkDir?.newFile?.path)
    }
    
    func test_statusEntry_should_return_pathInWorkdir() {
        let repo = Repository.t_randomRepo()
        _ = repo.flatMap { $0.t_write(file: .fileA, with: .random) }
        
        let status = repo.flatMap { $0.status() }
            .shouldSucceed()!
    }

}
