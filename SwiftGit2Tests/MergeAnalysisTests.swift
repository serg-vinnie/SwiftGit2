
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
    
    func testFastForward_local() {
        let folder = root.sub(folder: "fastForward_2")
        
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()!
        
        let dst = folder.with(repo: "dst", content: .clone(src.url, cloneOptions))
            .shouldSucceed()!
        
        (src.repo | { $0.t_commit(file: .fileA, with: .random, msg: "second commit") })
            .shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .upToDate)
        
        (dst.repo | { $0.fetch(.HEAD, options: FetchOptions(auth: .credentials(.none)))})
            .shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: [.fastForward, .normal])

        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.none)))
        
        (dst.repo | { $0.pull(.HEAD, options: options) })
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }

    
//    func testFastForward() {
//        let folder = root.sub(folder: "fastForward")
//        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
//        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
//        
//        repo2.t_push_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
//            .shouldSucceed("repo2 push")
//
//        repo1.mergeAnalysisUpstream(.HEAD)
//            .assertEqual(to: .upToDate)
//
//        repo1.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
//            .shouldSucceed()
//
//        repo1.mergeAnalysisUpstream(.HEAD)
//            .assertEqual(to: [.fastForward, .normal])
//
//        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
//        
//        repo1.pull(.HEAD, options: options)
//            .assertEqual(to: .fastForward, "pull fast forward merge")
//    }

    func testThreWaySuccess() {
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
    
    func testShouldHasConflict() {
        let folder = root.sub(folder: "ShouldHasConflict")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
        
        // fileA
        repo2.t_push_commit(file: .fileLong, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .shouldSucceed("t_push_commit")
        
        // Same fileA
        repo1.t_commit(file: .fileLong, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
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
    
    func test_should_success_mine() throws {
        let folder = createConflict(subFolder: "test_should_success_mine")
        
        let repoID = RepoID(url: folder.sub(folder: "repo1").url )
        
        Conflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
        
        Conflicts(repoID: repoID)
            .all()
            .map { $0.count }
            .assertEqual(to: 1)
        
        let first = Conflicts(repoID: repoID)
            .all()
            .maybeSuccess!.first!
        
        Conflicts(repoID: repoID)
            .resolve(path: first.our.path, resolveAsTheir: true)
            .shouldSucceed("Conflict Resolved")
        
        Conflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
    }
    
//    func test_should_success_their() throws {
//        try createConflict(subFolder: "test_should_success_their")
//    }
//
//    func test_should_success_both() throws {
//        try createConflict(subFolder: "test_should_success_both")
//    }
}





extension MergeAnalysisTests {
    private func createConflict(subFolder: String) -> TestFolder {
        let folder = root.sub(folder: subFolder)
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, cloneOptions)).repo.shouldSucceed("repo2 clone")!
        
        // fileA
        repo2.t_push_commit(file: .fileLong, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .shouldSucceed()
        
        // Same fileA
        repo1.t_commit(file: .fileLong, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .shouldSucceed()
        
        repo1.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()
        
        let merge = repo1.mergeAnalysisUpstream(.HEAD)
            .assertNotEqual(to: [.fastForward])
        
        XCTAssert(merge == .normal)
        
        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        repo1.pull(.HEAD, options: options)
            .map { $0.hasConflict }
            .assertEqual(to: true)
        
        return folder
    }
}
