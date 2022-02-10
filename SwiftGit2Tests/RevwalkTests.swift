//
//  RevwalkTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 29.06.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Essentials
import EssetialTesting
@testable import SwiftGit2
import XCTest

class RevwalkTests: XCTestCase {

    var repo1: Repository!
    var repo2: Repository!

    override func setUpWithError() throws {
        let info = PublicTestRepo()

        repo1 = Repository.clone(from: info.urlSsh, to: info.localPath, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone 1")

        repo2 = Repository.clone(from: info.urlSsh, to: info.localPath2, options: CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))
            .shouldSucceed("clone 2")
    }
    
    func testRevwalk() {
        
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
        
        repo2.fetch(.HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()
        
        repo2.mergeAnalysisUpstream(.HEAD)
            .assertEqual(to: [.fastForward, .normal])
        
        repo2.pendingCommitsOIDs(.HEAD, .fetch)
            .map { $0.count }
            .assertEqual(to: 1, "repo2.pendingCommits(.HEAD, .fetch)")
    }
}
