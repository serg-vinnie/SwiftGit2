
import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class MergeAnalysisTests: XCTestCase {
    var repo1: Repository!
    var repo2: Repository!

    override func setUpWithError() throws {
        let info = PublicTestRepo()

        repo1 = Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone 1")

        repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone 2")
    }

    override func tearDownWithError() throws {}

    func testFastForward() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
            .shouldSucceed()

        repo1.mergeAnalysisUpstream(.HEAD)
            .assertEqual(to: .upToDate)

        repo1.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()

        repo1.mergeAnalysisUpstream(.HEAD)
            .assertEqual(to: [.fastForward, .normal])

        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        repo1.pull(.HEAD, options: options)
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }

    func testThreWaySuccess() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY **SUCCESSFUL** MERGE test")
            .shouldSucceed()

        repo1.t_commit(file: .fileB, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .shouldSucceed()

        repo1.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()

        let merge = repo1.mergeAnalysisUpstream(.HEAD)
            .assertNotEqual(to: [.fastForward], "merge analysis")

        XCTAssert(merge == .normal)

        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        repo1.pull(.HEAD, options: options)
            .assertEqual(to: .threeWaySuccess)
    }
    
    func testShouldHasConflict() throws {
        // fileA
        repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .shouldSucceed("t_push_commit")
        
        // Same fileA
        repo1.t_commit(file: .fileA, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .shouldSucceed()
        
        repo1.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()
        
        let merge = repo1.mergeAnalysisUpstream(.HEAD)
            .assertNotEqual(to: [.fastForward])
        
        XCTAssert(merge == .normal)
        
        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        repo1.pull(.HEAD, options: options)
            .map { $0.hasConflict }
            .assertEqual(to: true, "pull has conflict")
    }
}
