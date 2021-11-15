import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusEntryTests: XCTestCase {
    func test_new_file_should_have_indexToWorkDir() {
        let status = Repository
            .t_randomRepo()
            .flatMap { $0.t_with(file: .fileA, with: .random) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        let entrie = status[0]
        XCTAssert(entrie.indexToWorkDir != nil)
        XCTAssert(entrie.headToIndex == nil)
        
        XCTAssert(entrie.indexToWorkDir?.oldFile != nil)
        XCTAssert(entrie.indexToWorkDir?.newFile != nil)
        XCTAssert(entrie.indexToWorkDir?.oldFile?.path == entrie.indexToWorkDir?.newFile?.path)
    }
    
    func test_new_file_should_return_pathInWorkDir() {
        let status = Repository.t_randomRepo()
            .flatMap { $0.t_with(file: .fileA, with: .random) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].pathInWorkDir == "")
    }
    
    func test_should_stage_new_file() {
        let url = URL.randomTempDirectory().maybeSuccess!
        
        let status = Repository.create(at: url)
            .flatMap { $0.t_with(file: .fileA, with: .random) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        let entry = status[0]
        XCTAssert(entry.isStaged == false)
        
        let newStatus = Repository.at(url: url)
            .flatMap { $0.addBy(path: entry.pathInWorkDir!) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(newStatus[0].isStaged == true)
    }

}
