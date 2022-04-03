import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitDiscardTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitDiscardTests")
       
    func test_shouldDicardSingle() {
        let src = root.with(repo: "test_shouldDicardAll", content: .file(.fileA, .content1)).shouldSucceed()!
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 1, "status count is correct")
        
        let repoID = RepoID(url: src.url )
        
        _ = GitDiscard(repoID: repoID).path( TestFile.fileA.rawValue ).shouldSucceed()!
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0, "status count is correct")
    }
    
//    func test_shouldDicardAll() {
//        let src = root.with(repo: "test_shouldDicardAll", content: .files).shouldSucceed()!
//
////        root.with(repo: "test_shouldDicardAll", content: .file(.fileA, .)).shouldSucceed()!
////        root.with(repo: "test_shouldDicardAll", content: .file(.fileB, "asdf")).shouldSucceed()!
////        root.with(repo: "test_shouldDicardAll", content: .file(.fileLong, "asdf")).shouldSucceed()!
//
//        let repoID = RepoID(path: src.url.path )
//
//        GitDiscard(repoID: repoID).all().shouldSucceed()!
//    }
}
