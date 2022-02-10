//
//  SwiftGit2Tests.swift
//  SwiftGit2Tests
//
//  Created by loki on 16.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Essentials
@testable import SwiftGit2
import XCTest



class RepositoryRemoteTests: XCTestCase {
    override func setUpWithError() throws {}
    override func tearDownWithError() throws {}

    func testHttpsAnonymouseClone() {
        let info = PublicTestRepo()

        Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.default))))
            .shouldSucceed("clone")
    }

    func testSSHDefaultClone() {
        let info = PublicTestRepo()

        Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone")
    }

    func testRemoteConnect() {
        let info = PublicTestRepo()

        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.default))))
            .shouldSucceed("clone") else { fatalError() }

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

        guard let repo = Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone") else { fatalError() }

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
        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.default))))
            .shouldSucceed("clone") else { fatalError() }

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .shouldSucceed("t_commit")

        // push should FAIL
        repo.push(.HEAD, options: PushOptions(auth: .credentials(.default)))
            .shouldFail("push")
    }

    func testPushNoRemote() {
        let repo_ = GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .shouldSucceed("create repo")

        // for some reason it doesnt compile "let repo = repo"
        guard let repo = repo_ else { fatalError() }

        repo.t_commit(file: .fileA, with: .random, msg: "fileA random content")
            .shouldSucceed("t_commit")

        // push should FAIL
        repo.push(.HEAD, options: PushOptions(auth: .credentials(.default)))
            .shouldFail("push")
    }
    
    func testUpstreamExists() {
        let info = PublicTestRepo()

        guard let repo = Repository.clone(from: info.urlHttps, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.default))))
            .shouldSucceed("clone") else { fatalError() }
        
        repo.upstreamExistsFor(.HEAD)
            .shouldSucceed("upstreamExistsFor")
        
        repo.createBranch(from: .HEAD, name: "newBranch", checkout: true)
            .flatMap { repo.upstreamExistsFor(.branch($0)) }
            .assertEqual(to: false, "upstreamExistsFor newBranch")
        
        repo.t_commit(msg: "testcommit")
            .shouldSucceed()
        
        repo.pendingCommitsCount(.branchShortName("newBranch"))
            .assertEqual(to: .publish_pending(1), ".pendingCommitsCount(.branchShortName(newBranch))")
        
//        repo.pendingCommits(.branchShortName("newBranch"), .push)
//            .shouldSucceed("repo.pendingCommits(.branch($0), .push)")
        
    }
    
    func testSshAll() {
        Credentials.sshAll
            .shouldSucceed("clone")
    }
}
