
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
        createConflict(subFolder: "test_should_success_mine")
        
        let repoID = RepoID(url: root.sub(folder: "test_should_success_mine").url.appendingPathComponent("repo1") )
        
        let cfl = Conflicts(repoID: repoID)
        
        _ = cfl.exist().shouldSucceed("Conflicts exist")!
        
        let firstConflict = cfl.all().shouldSucceed("Conflicts exist")!.first!
        
        
        resolveConflict(repoID: repoID, conflict: firstConflict, resolveAsTheir: false)
            .shouldSucceed("Conflict resolved as mine")
        
        _ = repoID.repo.flatMap { $0.index() }
            .map{ $0.hasConflicts }
            .assertEqual(to: false, "has NO conflicts. This is ok")
        
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
    private func createConflict(subFolder: String) {
        let folder = root.sub(folder: subFolder)
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
    
    private func getFirstConflict(repoID: RepoID) -> Index.Conflict  {
        repoID.repo.flatMap{ $0.index() }
            .flatMap{ $0.conflicts() }
            .map{ $0.first! }
            .shouldSucceed("First conflict found")!
    }
}


func resolveConflict(repoID: RepoID, conflict: Index.Conflict, resolveAsTheir: Bool) -> R<Void> {
    let repo = repoID.repo.shouldSucceed("Got the Repo")!
    let rConflict: R<Index.Conflict> = .success(conflict)
    
    
    let index = repo.index()
    
    return zip(index, rConflict)
        .flatMap { index, conflict -> R<()> in
            let sideEntry = resolveAsTheir ? conflict.their : conflict.our
            
            return index
                .removeAll(pathPatterns: [sideEntry.path])
                // Видаляємо конфлікт
                .map{ index.conflictRemove(relPath: sideEntry.path) }
                // додаємо файл чи сабмодуль в індекс
                .flatMap { _ -> R<()> in
                    return index.add(sideEntry)
                }
                // чекаутим файл чи сабмодуль з цього індекса
                .flatMap { _ in
                    repo.checkout( index: index, strategy: [.Force, .DontWriteIndex])//, relPaths: [sideEntry.path] )
                }
        }
        .flatMap{ _ in .success(()) }
}

// HELPERS
// CODE DUPLICATE FROM ASYNC NINJA
/// Combines successes of two failables or returns fallible with first error
public func zip<A, B>(
  _ a: Fallible<A>,
  _ b: Fallible<B>
  ) -> Fallible<(A, B)> {
  switch (a, b) {
  case let (.success(successA), .success(successB)):
    return .success((successA, successB))
  case let (.failure(failure), _),
       let (_, .failure(failure)):
    return .failure(failure)
  default:
    fatalError()
  }
}
