import Essentials
@testable import SwiftGit2
import XCTest
import EssentialsTesting

class GitDiscardTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitDiscardTests")
       
    func test_shouldDicardSingle() {
        let src = root.with(repo: "dicardSingle", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(url: src.url )
        
        src.statusCount
            .assertEqual(to: 1, "status count is correct")
        
        GitDiscard(repoID: repoID).path( TestFile.fileA.fileName )
            .shouldSucceed()
        
        src.statusCount
            .assertEqual(to: 0, "status count is correct")
    }
    
    func test_shouldDicardSingle_oneOfMany() {
        let src = root.with(repo: "dicardSingle_oneOfMany", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(url: src.url )
        
        GitDiscard(repoID: repoID).path( TestFile.fileA.fileName )
            .shouldSucceed()
        
        ( repoID.repo
            | { $0.t_with(file: .fileA, with: .content3) }
            | { $0.t_with(file: .fileB, with: .content2) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 2, "status count is correct")
        
        GitDiscard(repoID: repoID).path(TestFile.fileA.fileName).shouldSucceed()
        
        src.statusCount.assertEqual(to: 1, "status count is correct")
    }
    
    func test_shouldDicardSingle_oneOfMany_detachedHead() {
        let src = root.with(repo: "dicardSingle_oneOfMany_detachedHead", content: .commit(.fileA, .random, "")).shouldSucceed()!
        let repoID = src.repoID
        
        ( repoID.repo
            | { $0.t_with(file: .fileA, with: .content3) }
            | { $0.t_with(file: .fileB, with: .content2) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 2, "status count is correct")
        
        (repoID.HEAD | { $0.detach() } ).shouldSucceed("detach1")

        GitDiscard(repoID: repoID).path(TestFile.fileA.fileName).shouldSucceed()
        
        src.statusCount.assertEqual(to: 1, "status count is correct")
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
        
        src.statusCount.assertEqual(to: 3, "status count is correct")
        
        GitDiscard(repoID: repoID).all().shouldSucceed()
        
        src.statusCount.assertEqual(to: 0, "status count is correct")
    }
    
    func test_shouldDicardAll_headIsBorn() {
        let src = root.with(repo: "DicardAll_bornHead", content: .commit(.fileA, .content1, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 2, "status count is correct")
        
        GitDiscard(repoID: repoID).all().shouldSucceed()
        
        src.statusCount.assertEqual(to: 0, "status count is correct")
    }
    
    func test_shouldDicardAll_headIsDetached() {
        let src = root.with(repo: "DicardAll_headIsDetached", content: .commit(.fileA, .content1, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 2)
        
        (repoID.repo | { $0.detachHEAD() })
            .shouldSucceed()
        
        GitDiscard(repoID: repoID).all()
            .shouldSucceed("discard all")
        
        src.statusCount.assertEqual(to: 0, "status count is correct")
    }
    
    func test_discardByEntry_oneOfLot() {
        let src = root.with(repo: "DiscardByEntry_oneOfLot", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 3, "status count is correct")
        
        let entry = src.repo.flatMap { $0.status() }.maybeSuccess!.first!
        
        GitDiscard(repoID: repoID).entry(entry).shouldSucceed()
        
        src.statusCount.assertEqual(to: 2, "status count is correct")
    }
    
    func test_discardFew() {
        let src = root.with(repo: "DiscardByEntry_oneOfLot", content: .file(.fileA, .content1)).shouldSucceed()!
        
        let repoID = RepoID(path: src.url.path )
        
        ( repoID.repo
            | { $0.t_with(file: .fileB, with: .content2) }
            | { $0.t_with(file: .fileC, with: .content3) }
        )
        .shouldSucceed()
        
        src.statusCount.assertEqual(to: 3, "status count is correct")
        
        GitDiscard(repoID: repoID).paths([TestFile.fileA.fileName, TestFile.fileB.fileName ]).shouldSucceed()
        
        src.statusCount.assertEqual(to: 1, "status count is correct")
    }
}
