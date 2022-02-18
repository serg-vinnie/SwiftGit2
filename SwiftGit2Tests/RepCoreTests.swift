//
//  RepCoreTests.swift
//  SwiftGit2Tests
//
//  Created by loki on 18.02.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import XCTest
import EssetialTesting
import SwiftGit2

class TestContainer {
    let repoID: RepoID
    init(repoID: RepoID) {
        self.repoID = repoID
        print("TestContainer.init \(repoID)")
    }
    deinit {
        print("TestContainer.deinit \(repoID)")
    }
}

class RepCoreTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "RepCoreTests")

    func test_shoudAppendRootRepo() {
        let folder = root.sub(folder: "AppendRootRepo").cleared().shouldSucceed()!
        
        folder.with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
            .flatMap { $0.with(submodule: "sub_repo", content: .commit(.fileB, .random, "initial commit")) }
            .shouldSucceed("addSub")

        let repoID = RepoID(url: folder.sub(folder: "main_repo").url)
        
        let repCore = RepCore<TestContainer>.empty.appendingRoot(repoID: repoID, block: { TestContainer(repoID: $0) })
            .shouldSucceed("RepCore")!
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
