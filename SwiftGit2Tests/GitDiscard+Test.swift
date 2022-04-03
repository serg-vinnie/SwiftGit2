import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitDiscardTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitDiscardTests")
       
    func test_shouldDicardSingle() {
        let src = root.with(repo: "dicardSingle", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(url: src.url )
        
        repoID.repo.flatMap { $0.status() }
            .map{ $0.count }
            .assertEqual(to: 1, "status count is correct")
        
        GitDiscard(repoID: repoID).path( TestFile.fileA.rawValue )
            .shouldSucceed()
        
        /// ADD FILE
        (repoID.repo | { $0.t_with(file: .fileB, with: .random) })
            .shouldSucceed()
        ///
        
        repoID.repo.flatMap { $0.status() }
            .map{ $0.count }
            .assertEqual(to: 0, "status count is correct")
    }
    
    
    func test_shouldDicardAll() {
        let src = root.with(repo: "DicardAll", content: .empty).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileA, with: .content1) }
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 3, "status count is correct")
        
        GitDiscard(repoID: repoID).all().shouldSucceed()

        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0, "status count is correct")
    }
}
