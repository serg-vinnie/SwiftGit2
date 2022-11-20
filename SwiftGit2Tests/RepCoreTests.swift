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

public class TestContainer {
    static var counter = 0
    let repoID: RepoID
    init(repoID: RepoID) {
        TestContainer.counter += 1
        self.repoID = repoID
        print("INIT.TestContainer \(repoID)")
    }
    deinit {
        TestContainer.counter -= 1
        print("DE-INIT.TestContainer \(repoID)")
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
        
        var repCore = RepCore<TestContainer>.empty.appendingRoot(repoID: repoID, block: { TestContainer(repoID: $0) })
            .shouldSucceed("RepCore")!
        
        XCTAssert(TestContainer.counter == 2)
        
        repCore = repCore.removingRoot(repoID: repoID)
        
        XCTAssert(TestContainer.counter == 0)
    }

}
