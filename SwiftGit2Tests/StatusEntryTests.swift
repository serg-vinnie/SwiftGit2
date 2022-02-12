import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusEntryTests: XCTestCase {
    let folder = TestFolder.git_tests.sub(folder: "StatusEntryTests")
    
    func test_new_fileShouldHave_indexToWorkDir() {
        let status = folder.with(repo: "fileShouldHave_IndexToWorkDir", content: .file(.fileA, .random))
            .repo
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
    
    func test_statusShouldHave_stagePath() {
        folder.with(repo: "statusShouldHave_stagePath", content: .file(.fileA, .random))
            .repo 
            .flatMap { $0.status() }
            .map { $0[0].stagePath }
            .assertEqual(to: TestFile.fileA.rawValue)
    }
    
    func test_shouldStageNewFile() {
        let folder = self.folder.with(repo: "shouldStageNewFile", content: .file(.fileA, .random))
        
        let status = folder.repo
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].statuses == [.untracked] )
        XCTAssert(status[0].stageState != .staged)
        
        let newStatus = folder.repo
            .flatMap { $0.stage(.entry(status[0])) }
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(newStatus[0].stageState == .staged)
        XCTAssert(newStatus[0].statuses == [.added] )
    }
    
    func test_commitedFile_ShouldReturn_stagePath() {
        let commitDetails = folder.with(repo: "commitedFile_ShouldReturn_stagePath", content: .commit(.fileA, .random, "...."))
            .repo
            .flatMap { $0.deltas(target: .HEADorWorkDir, findOptions: .all) }
            .shouldSucceed()!
        
        XCTAssert(commitDetails.deltasWithHunks[0].stagePath == TestFile.fileA.rawValue)
        XCTAssert(commitDetails.deltasWithHunks[0].statuses == [.added])
    }
    
    func test_shouldReturn_EntyFileInfo_Commit() {
        folder.with(repo: "shouldReturn_EntyFileInfo_Commit", content: .commit(.fileA, .random, "...."))
            .repo
            .flatMap { $0.deltas(target: .HEADorWorkDir, findOptions: .all) }
            .flatMap { $0.deltasWithHunks[0].entryFileInfo }
            .shouldSucceed()
    }
    
    func test_shouldReturn_EntyFileInfo_Commit_Rename() {
        let folder = folder.with(repo: "shouldReturn_EntyFileInfo_Commit_Rename", content: .commit(.fileA, .random, "...."))
            .shouldSucceed()!
        
        folder.url.moveFile(at: TestFile.fileA.rawValue, to: TestFile.fileB.rawValue)
        
        let status = folder.repo
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        XCTAssert(status[0].statuses == [.deleted])
        XCTAssert(status[1].statuses == [.untracked])
        
        folder.repo
            .flatMap { $0.stage(.entry(status[0])) }
            .flatMap { $0.stage(.entry(status[1])) }
            .flatMap { $0.commit(message: "rename", signature: GitTest.signature) }
            .shouldSucceed()
        
        let deltas = folder.repo
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
