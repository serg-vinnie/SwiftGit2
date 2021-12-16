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
        
        XCTAssert(entrie.statuses == [.untracked] )
        
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
        
        XCTAssert(status[0].stagePath == TestFile.fileA.rawValue)
    }
    
    func test_should_stage_new_file() {
        let url = URL.randomTempDirectory().maybeSuccess!
        
        let status = Repository.create(at: url)
            .flatMap { $0.t_with(file: .fileA, with: .random) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].statuses == [.untracked] )
        XCTAssert(status[0].stageState != .staged)
        
        let newStatus = Repository.at(url: url)
            .flatMap { $0.stage(.entry(status[0])) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(newStatus[0].stageState == .staged)
        XCTAssert(newStatus[0].statuses == [.added] )
    }
    
    func test_commit_file_should_return_pathInWd() {
        let commitDetails = Repository.t_randomRepo()
            .flatMap { $0.t_with_commit(file: .fileA, with: .random, msg: "....") }
            .flatMap { $0.deltas(target: .HEADorWorkDir, findOptions: .all) }
            .shouldSucceed()!
        
        XCTAssert(commitDetails.deltasWithHunks[0].stagePath == TestFile.fileA.rawValue)
        XCTAssert(commitDetails.deltasWithHunks[0].statuses == [.added])
    }
    
    func test_should_return_EntyFileInfo_Commit() {
        _ = Repository.t_randomRepo()
            .flatMap { $0.t_with_commit(file: .fileA, with: .random, msg: "....") }
            .flatMap { $0.deltas(target: .HEADorWorkDir, findOptions: .all) }
            .flatMap { $0.deltasWithHunks[0].entryFileInfo }
            .shouldSucceed()!
    }
    
    func test_should_return_EntyFileInfo_Commit_rename() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString), isDirectory: true)
        
        print("REPO_URL \(url.path)")
        
        Repository.create(at: url)
            .flatMap { $0.t_with_commit(file: .fileA, with: .random, msg: "....") }
            .shouldSucceed()
        
        url.moveFile(at: TestFile.fileA.rawValue, to: TestFile.fileB.rawValue)
        
        let status = Repository.create(at: url)
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].statuses == [.deleted])
        XCTAssert(status[1].statuses == [.untracked])
        
        Repository.at(url: url)
            .flatMap { $0.stage(.entry(status[0])) }
            .flatMap { $0.stage(.entry(status[1])) }
            .flatMap { $0.commit(message: "rename", signature: GitTest.signature) }
            .shouldSucceed()
        
        let deltas = Repository.at(url: url)
            .flatMap { $0.deltas(target: .HEADorWorkDir, findOptions: .all) }
            .shouldSucceed("deltas")!
        
        XCTAssert(deltas.deltasWithHunks[0].statuses == [.renamed])
        
        if case let .success(.renamed(a, b)) = deltas.deltasWithHunks[0].entryFileInfo {
            XCTAssert(a == TestFile.fileA.rawValue)
            XCTAssert(b == TestFile.fileB.rawValue)
        } else {
            XCTAssert(false)
        }
    }

}

extension URL {
    func moveFile(at: String, to _to: String) {
        let from  = self.appendingPathComponent(at)
        let to  = self.appendingPathComponent(_to)
        try! FileManager.default.moveItem(at: from, to: to)
    }
}
