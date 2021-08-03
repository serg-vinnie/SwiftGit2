
import Essentials
@testable import SwiftGit2
import XCTest

class MergeAnalysisTests: XCTestCase {
    var repo1: Repository!
    var repo2: Repository!

    override func setUpWithError() throws {
        let info = PublicTestRepo()

        repo1 = Repository.clone(from: info.urlSsh, to: info.localPath)
            .assertFailure("clone 1")

        repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2)
            .assertFailure("clone 2")
    }

    override func tearDownWithError() throws {}

    func testFastForward() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "for FAST FORWARD MERGE Test")
            .assertFailure()

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: .upToDate)

        repo1.fetch(.HEAD)
            .assertFailure()

        repo1.mergeAnalysis(.HEAD)
            .assertEqual(to: [.fastForward, .normal])

        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }

    func testThreWaySuccess() throws {
        repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        repo1.t_commit(file: .fileB, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()

        repo1.fetch(.HEAD)
            .assertFailure()

        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward], "merge analysis")

        XCTAssert(merge == .normal)

        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertEqual(to: .threeWaySuccess)
    }

    func testThreeWayConflict() throws {
        // fileA
        let commit = repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .assertFailure("t_push_commit")
        
        // Same fileA
        repo1.t_commit(file: .fileA, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()
        
        repo1.fetch(.HEAD)
            .assertFailure()
        
        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward])
        
        // MERGE_HEAD creation
        OidRevFile( repo: repo1, type: .MergeHead)?
            .setOid(from: commit)
            .save()
        
        XCTAssert(merge == .normal)
        
        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertBlock("pull has conflict") { $0.hasConflict }
    }
    
    func testMerge() throws {
        // fileA
        let commitToMerge = repo2.t_push_commit(file: .fileA, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .assertFailure("t_push_commit")
        
        // Same fileA
        repo1.t_commit(file: .fileA, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .assertFailure()
        
        repo1.fetch(.HEAD)
            .assertFailure()
        
        let merge = repo1.mergeAnalysis(.HEAD)
            .assertNotEqual(to: [.fastForward])
        
        // MERGE_HEAD creation
        OidRevFile( repo: repo1, type: .MergeHead)?
            .setOid(from: commitToMerge)
            .save()
        
        // MERGE_MSG creation
        RevFile(repo: repo1, type: .MergeMsg)?
            .set(content: "UKS RULEZZ")
            .save()
        
        XCTAssert(merge == .normal)
        
        repo1.pull(.HEAD, signature: GitTest.signature)
            .assertBlock("pull has conflict") { $0.hasConflict }
        
        XCTAssert( commitToMerge != nil )
        
        let parents = combine(repo1.headCommit(), .success(commitToMerge!) )
                    .map { [$0, $1] }
        
        parents
            .flatMap {
                repo1.merge(our: $0[0], their: $0[1] )
            }
            .assertFailure()
    }
}
