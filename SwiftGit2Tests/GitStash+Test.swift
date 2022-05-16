import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitStashTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitStashTests")
    
    func test_stashSaveAndStashList() {
        let folder = root.with(repo: "stashSave", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 2)
    }
    
    func test_stashLoad() {
        let folder = root.with(repo: "stashLoad", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        
        let stashItems = gitStash.items().shouldSucceed()!
        let stash = stashItems.first!
        
        gitStash.load(stash)
        
        XCTAssertEqual(stashItems.count, 1)
        gitStash.repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 2)
    }
    
    func test_stashRemove() {
        let folder = root.with(repo: "stashRemove", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        
        let firstStash = gitStash.items().shouldSucceed()!.first!
        
        gitStash.remove(firstStash).shouldSucceed()!
        
        let items = gitStash.items().shouldSucceed()!
        
        XCTAssertEqual(items.count, 0)
        repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0)
    }
}

///////////////////////////////////
///HELPERS
///////////////////////////////////

fileprivate func createStash(folder: TestFolder, gitStash: GitStash, expectedStashCount: Int) {
    try? File(url: folder.url.appendingPathComponent("file_1.txt")).setContent("file_1")
    try? File(url: folder.url.appendingPathComponent("file_2.txt")).setContent("file_2")
    
    _ = gitStash.repoID.repo.map{ $0.stage(.all) }.shouldSucceed()!
    
    _ = gitStash.save(signature: .test, message: UUID().uuidString)
        .shouldSucceed()
    
    let stashItems = gitStash.items().shouldSucceed()!
    
    XCTAssertEqual(stashItems.count, expectedStashCount)
    gitStash.repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0)
}
