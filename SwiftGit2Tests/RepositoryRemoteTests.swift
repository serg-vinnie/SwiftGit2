import Essentials
import EssentialsTesting
@testable import SwiftGit2
import XCTest

class RepositoryRemoteTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "RepositoryRemoteTests")
    
//    func test_accessShouldFail() {
//        let repo = root.with(repo: "test_accessShouldFail", content: .empty).repo.maybeSuccess!
//        
//        repo.createRemote(url: PublicTestRepo().urlSsh.path)
//            .flatMap { $0.connect(direction: .fetch, auth: .credentials(.none)) }
//            .shouldSucceed("connect")
//    }
    
    func test_credentilas_ShouldBeReusable() {
        let auth : Auth = .credentials(.sshDefault)
        let folder = root.sub(folder: "credentilas_ShouldBeReusable")
        
        folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: auth))))
            .shouldSucceed("repo1 clone")
        folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: auth))))
            .shouldSucceed("repo2 clone")
    }

    
    func testHttpsAnonymouseClone() {
        let info = PublicTestRepo()
        
        root.with(repo: "HttpsAnonymouseClone", content: .clone(info.urlHttps, CloneOptions(fetch: FetchOptions(auth: .credentials(.default)))))
            .shouldSucceed("HttpsAnonymouseClone")
    }

    func testSSHDefaultClone() {
        let info = PublicTestRepo()

        root.with(repo: "SSHDefaultClone", content: .clone(info.urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)))))
            .shouldSucceed("SSHDefaultClone")
    }

    func testRemoteConnect() {
        let info = PublicTestRepo()

        let repo = root.with(repo: "RemoteConnect", content: .clone(info.urlHttps, CloneOptions(fetch: FetchOptions(auth: .credentials(.default)))))
            .repo
            .shouldSucceed("clone")!

        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .fetch, auth: .credentials(.default)) } // shoud succeed
            .shouldSucceed("retmote.connect .fetch")

        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .push, auth: .credentials(.default)) } // should fail
            .shouldFail("retmote.connect .push")
        
        let creds = [GitTest.credentials_01, GitTest.credentials_bullshit] // last will be tried first
        
        repo.getRemoteFirst()
            .flatMap { $0.connect(direction: .push, possibleCreds: creds) }
            .shouldSucceed("retmote.connect .push") // should succeed
    }

    func testPush() {
        let info = PublicTestRepo()

        let repo = root.with(repo: "Push", content: .clone(info.urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)))))
            .repo
            .shouldSucceed("clone")!

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .shouldSucceed("t_commit")

        repo.detachHEAD().shouldSucceed("detachHEAD")

        repo.push(.HEAD, options: PushOptions(auth: .credentials(.sshDefault)))
            .shouldFail("push")

        repo.detachedHeadFix().shouldSucceed("detachedHeadFix")

        repo.push(.HEAD, options: PushOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed("push")
    }

    func testPushNoWriteAccess() {
        let info = PublicTestRepo()

        // use HTTPS anonymous access
        let repo = root.with(repo: "PushNoWriteAccess", content: .clone(info.urlHttps, CloneOptions(fetch: FetchOptions(auth: .credentials(.default)))))
            .repo
            .shouldSucceed("clone")!

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .shouldSucceed("t_commit")

        // push should FAIL
        repo.push(.HEAD, options: PushOptions(auth: .credentials(.default)))
            .shouldFail("push")
    }

    func testPushNoRemote() {
        root.with(repo: "PushNoRemote", content: .commit(.fileA, .random, "bla bla"))
            .repo
            .flatMap { $0.push(.HEAD, options: PushOptions(auth: .credentials(.default))) }
            .shouldFail("push")
    }
    
    func testUpstreamExists() {
        let info = PublicTestRepo()

        let repo = root.with(repo: "UpstreamExists", content: .clone(info.urlHttps, CloneOptions(fetch: FetchOptions(auth: .credentials(.default)))))
            .repo
            .shouldSucceed("clone")!
        
        repo.upstreamExistsFor(.HEAD)
            .shouldSucceed("upstreamExistsFor")
        
        repo.createBranch(from: .HEAD, name: "newBranch", checkout: true)
            .flatMap { repo.upstreamExistsFor(.branch($0)) }
            .assertEqual(to: false, "upstreamExistsFor newBranch")
        
        repo.t_commit(msg: "testcommit")
            .shouldSucceed()
        
        repo.pendingCommitsCount(.branchShortName("newBranch"))
            .assertEqual(to: .publish_pending(1), ".pendingCommitsCount(.branchShortName(newBranch))")
        
    }
    
    func testSshAll() {
        Credentials.sshAll
            .shouldSucceed("sshAll")
    }
}
