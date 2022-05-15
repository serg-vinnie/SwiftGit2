import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitStashTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitStashTests")
    
    func test_stashList() {
        //let src = root.with(repo: "stashList", content: .empty).shouldSucceed()!
        
        let repoID = RepoID(url: "/Users/uks/dev/taogit".asURL() )
        
        let gitStash = GitStash(repoID: repoID)
        
        let items = gitStash.items().shouldSucceed()!
        
        XCTAssertEqual(items.count, 0)
    }
    
    func test_stashSave() {
        
    }
    
    func test_stashLoad() {
        
    }
}
