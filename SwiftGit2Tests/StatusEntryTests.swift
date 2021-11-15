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
        
        XCTAssert(status[0].pathInWorkDir == TestFile.fileA.rawValue)
    }
    
    func test_should_stage_new_file() {
        let url = URL.randomTempDirectory().maybeSuccess!
        
        let status = Repository.create(at: url)
            .flatMap { $0.t_with(file: .fileA, with: .random) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].stageState != .staged)
        
        let newStatus = Repository.at(url: url)
            .flatMap { $0.addBy(path: status[0].pathInWorkDir!) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(newStatus[0].stageState == .staged)
    }
    
    func test_commit_file_should_return_pathInWd() {
        let status = Repository.t_randomRepo()
            .flatMap { $0.t_with_commit(file: .fileA, with: .random, msg: "....") }
            ////.flatMap { $0.deltas(target: .)() }
            .shouldSucceed()!
  
    }

}
