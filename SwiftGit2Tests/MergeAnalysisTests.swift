
import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class MergeAnalysisTests: XCTestCase {
    let root  = TestFolder.git_tests.sub(folder: "MergeAnalysisTests")
        
    func test_shouldMergeFastForward() {
        let folder = root.sub(folder: "fastForward").cleared().shouldSucceed()!
        
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        (src.repo | { $0.t_commit(file: .fileA, with: .random, msg: "Commit 2") })
            .shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .upToDate)
        
        (dst.repo | { $0.fetch(.HEAD, options: .local)})
            .shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: [.fastForward, .normal])
        
        (dst.repo | { $0.pull(.HEAD, options: .local) })
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }
    
    func test_shouldMergeThreeWay() {
        let folder = root.sub(folder: "threeWay").cleared().shouldSucceed()!
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!

        (src.repo | { $0.t_commit(file: .fileA, with: .random, msg: "File A") })
            .shouldSucceed()
        (dst.repo | { $0.t_commit(file: .fileB, with: .random, msg: "File B") })
            .shouldSucceed()
        
        (dst.repo | { $0.fetch(.HEAD, options: .local) })
            .shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .normal)
        
        (dst.repo | { $0.pull(.HEAD, options: .local) })
            .assertEqual(to: .threeWaySuccess, "Pull")
    }
    
    func test_shoulConflict() {
        let folder = root.sub(folder: "conflict").cleared().shouldSucceed()!
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!

        (src.repo | { $0.t_commit(file: .fileA, with: .random, msg: "File A") })
            .shouldSucceed()
        (dst.repo | { $0.t_commit(file: .fileA, with: .random, msg: "File A") })
            .shouldSucceed()
        
        (dst.repo | { $0.fetch(.HEAD, options: .local) })
            .shouldSucceed()
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .normal)
        
        (dst.repo | { $0.pull(.HEAD, options: .local) })
            .map { $0.hasConflict }
            .assertEqual(to: true, "Pull has conflict")

    }
    
    func test_shouldConflict2() throws {
        let folder = root.sub(folder: "conflict").cleared().shouldSucceed()!
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!

        (src.repo | { $0.t_commit(file: .fileA, with: .random, msg: "File A") })
            .shouldSucceed()
        (dst.repo | { $0.t_commit(file: .fileA, with: .random, msg: "File A") })
            .shouldSucceed()
                
        (dst.repo | { $0.pull(.HEAD, options: .local) })
            .shouldSucceed()

        // -------------------------------------------------------------------
        
        let repoID = RepoID(url: dst.url )
        
        Conflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
        
        Conflicts(repoID: repoID)
            .all()
            .map { $0.count }
            .assertEqual(to: 1)
        
        let path = TestFile.fileA.rawValue
        
//        Conflicts(repoID: repoID)
//            .resolve(path: path, resolveAsTheir: true)
//            .shouldSucceed("Conflict Resolved")
        
//        Conflicts(repoID: repoID)
//            .exist()
//            .assertEqual(to: false)
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
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, .ssh)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, .ssh)).repo.shouldSucceed("repo2 clone")!
        
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
