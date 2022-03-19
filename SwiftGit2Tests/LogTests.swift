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
    
    func test_generate100k_commits() {
        let big_repo = root.with(repo: "big_repo", content: .empty).shouldSucceed()!
        
        for i in 0..<10000 {
            _ = (big_repo.repo | { $0.commit(message: "commit \(i)", signature: .test) })
        }
        
        let log = LogCache(repoID: RepoID(url: big_repo.url))
        
        self.measure {
            log.fetchHEAD()
        }
        
//        self.measure {
//            log.fetchHEAD_Commits()
//        }
    }

    func testPerformanceExample() {
        let url = URL.userHome.appendingPathComponent("/dev/taogit")
        let log = LogCache(repoID: RepoID(url: url))

        self.measure {
            log.fetchHEAD()
        }
    }
    
    func testPerformanceExample2() {
        let url = URL.userHome.appendingPathComponent("/dev/taogit")
        let log = LogCache(repoID: RepoID(url: url))
        
        self.measure {
            log.fetchHEAD_Commits()
        }
    }

}
