
import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

fileprivate var cloneOptions : CloneOptions { CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))) }

class MergeAnalysisTests: XCTestCase {
    let root  = TestFolder.git_tests.sub(folder: "MergeAnalysisTests")
    
    func test_credentilas_ShouldBeReusable() {
        let folder = root.sub(folder: "credentilas_ShouldBeReusable")
        let options = CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, options))
            .shouldSucceed("repo1 clone")
        folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, options))
            .shouldSucceed("repo2 clone")
    }
    
    func testFastForward() throws {
        let folder = root.sub(folder: "fastForward")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
        
        repo2.t_push_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
            .shouldSucceed("repo2 push")

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
        let folder = root.sub(folder: "ThreeWayMerge")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
        
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
        let folder = root.sub(folder: "ShouldHasConflict")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
        
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
