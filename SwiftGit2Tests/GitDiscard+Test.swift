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
        
        repoID.repo.flatMap { $0.status() }
            .map{ $0.count }
            .assertEqual(to: 0, "status count is correct")
    }
    
    func test_shouldDicardSingle_oneOfLot() {
        let src = root.with(repo: "dicardSingle_oneOfLot", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(url: src.url )
        
        GitDiscard(repoID: repoID).path( TestFile.fileA.rawValue )
            .shouldSucceed()
        
        ( repoID.repo
            | { $0.t_with(file: .fileA, with: .content3) }
            | { $0.t_with(file: .fileB, with: .content2) }
        )
        .shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 2, "status count is correct")
        
        GitDiscard(repoID: repoID).path(TestFile.fileA.rawValue).shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 1, "status count is correct")
        
    }
    
    func test_shouldDicardAll_headIsUnborn() {
        let src = root.with(repo: "DicardAll_unbornHead", content: .empty).shouldSucceed()!
        
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
    
    func test_shouldDicardAll_headIsBorn() {
        let src = root.with(repo: "DicardAll_bornHead", content: .commit(.fileA, .content1, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 2, "status count is correct")
        
        GitDiscard(repoID: repoID).all().shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0, "status count is correct")
    }
    
    func test_discardByEntry_oneOfLot() {
        let src = root.with(repo: "DiscardByEntry_oneOfLot", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 3, "status count is correct")
        
        
        let entry = src.repo.flatMap { $0.status() }.maybeSuccess!.first!
        
        GitDiscard(repoID: repoID).entry(entry).shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 2, "status count is correct")
    }
    
    func test_discardFew() {
        let src = root.with(repo: "DiscardByEntry_oneOfLot", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 3, "status count is correct")
        
        GitDiscard(repoID: repoID).paths([TestFile.fileA.rawValue, TestFile.fileB.rawValue ]).shouldSucceed()
        
        src.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 1, "status count is correct")
    }
}
