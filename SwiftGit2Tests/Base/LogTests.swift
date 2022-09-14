//
//  LogTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 19.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class LogTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "LogTests")
    //lazy var big_repo : TestFolder = { root.sub }()
    
    func test_refLogCache() {
        let repo = root.with(repo: "refLogCache", content: .log(500)).shouldSucceed()!
        let repoID = RepoID(url: repo.url)
        let head = GitBranches(repoID).HEAD.shouldSucceed()!
        
        let cache = RefLogCache(ref: head, prefetch: 50)
        
        XCTAssert( cache.deque.count == 50)
    }
    
    
    override func setUp() {
        let repo_10k = root.sub(folder: "repo_10k")
        if !Repository.exists(at: repo_10k.url) {
            Repository.create(at: repo_10k.url)
                .shouldSucceed()
            
            for i in 1...10000 {
                (repo_10k.repo | { $0.t_commit(file: .fileA, with: .random, msg: "commit \(i)") })
                    .shouldSucceed()
                if i % 1000 == 0 {
                    print("\(i) commits generated")
                }
            }
        }
        
        let repo_50k = root.sub(folder: "repo_50k")
        if !Repository.exists(at: repo_50k.url) {
            Repository.create(at: repo_50k.url)
                .shouldSucceed()
            
            for i in 1...50000 {
                (repo_50k.repo | { $0.t_commit(file: .fileA, with: .random, msg: "commit \(i)") })
                    .shouldSucceed()
                if i % 1000 == 0 {
                    print("\(i) commits generated")
                }
            }
        }
    }
    
//    func test_measure_10k_oids() {
//        let big_repo = root.sub(folder: "repo_10k")
//        
//        self.measure {
//            LogCache(repoID: RepoID(url: big_repo.url))
//                .fetchHEAD()
//                .onSuccess { print("oids fetched: \($0.count)")}
//                .shouldSucceed()
//        }
//    }
//    
//    func test_measure_10k_commits() {
//        let big_repo = root.sub(folder: "repo_10k")
//        
//        self.measure {
//            LogCache(repoID: RepoID(url: big_repo.url))
//                .fetchHEAD_Commits()
//                .onSuccess { print("commits fetched: \($0.count)")}
//                .shouldSucceed()
//        }
//    }
//    
//    func test_measure_50k_oids() {
//        let big_repo = root.sub(folder: "repo_50k")
//        
//        self.measure {
//            LogCache(repoID: RepoID(url: big_repo.url))
//                .fetchHEAD()
//                .onSuccess { print("oids fetched: \($0.count)")}
//                .shouldSucceed()
//        }
//    }
//    
//    func test_measure_50k_commits() {
//        let big_repo = root.sub(folder: "repo_50k")
//        
//        self.measure {
//            LogCache(repoID: RepoID(url: big_repo.url))
//                .fetchHEAD_Commits()
//                .onSuccess { print("commits fetched: \($0.count)")}
//                .shouldSucceed()
//        }
//    }
}
