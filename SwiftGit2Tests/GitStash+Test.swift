import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitStashTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitStashTests")
    
    // included into test_stashSave
    //func test_stashList() {
    //}
    
    func test_stashSave() {
        let folder = root.with(repo: "stashSave", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        
        try? File(url: folder.url.appendingPathComponent("file_1.txt")).setContent("file_1")
        try? File(url: folder.url.appendingPathComponent("file_2.txt")).setContent("file_2")
        
        _ = repoID.repo.map{ $0.stage(.all) }.shouldSucceed()!
        
        let gitStash = GitStash(repoID: repoID)
        
        _ = gitStash.save(signature: .test, message: "stash_1")
            .shouldSucceed()
        
        let items = gitStash.items().shouldSucceed()!
        
        XCTAssertEqual(items.count, 1)
        repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0)
    }
    
    func test_stashLoad() {
        
    }
}
