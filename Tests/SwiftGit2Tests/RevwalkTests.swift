import Essentials
import EssentialsTesting
@testable import SwiftGit2
import XCTest

class RevwalkTests: XCTestCase {
    let root  = TestFolder.git_tests.sub(folder: "RevwalkTests")

    func testRevwalk() {
        //let cloneOptions = CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)))
        let folder = root.sub(folder: "Revwalk")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))).repo.shouldSucceed("repo2 clone")!
        
        
        Revwalk.new(in: repo1)
            .flatMap { $0.push(range: "HEAD~20..HEAD") }
            .flatMap { $0.all() }
            .map { $0.count }
            .shouldSucceed("Revwalk.push(range")
        
        repo1.t_commit(msg: "commit for Revvalk")
            .shouldSucceed()

        repo1.pendingCommitsOIDs(.HEAD, .push)
            .map { $0.count }
            .assertEqual(to: 1, "repo1.pendingCommits(.HEAD, .push)")
                
        repo1.push(.HEAD, options: PushOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed("push")
        
        repo2.fetch(refspec: [], .HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()
        
        repo2.mergeAnalysisUpstream(.HEAD)
            .assertEqual(to: [.fastForward, .normal])
        
        repo2.pendingCommitsOIDs(.HEAD, .fetch)
            .map { $0.count }
            .assertEqual(to: 1, "repo2.pendingCommits(.HEAD, .fetch)")
    }
}
