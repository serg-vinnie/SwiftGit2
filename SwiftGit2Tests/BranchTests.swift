import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class BranchTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "BranchTests")
    
    func test_createBranch() {
        let folder = root.sub(folder: "createBranch").cleared().shouldSucceed()!
        let src = folder.with(repo: "createBr", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        
        src.repo
            .flatMap { $0.createBranch(from: .HEAD, name: "anotherBr", checkout: false) }
            .shouldSucceed()
        
        src.repo
            .flatMap { $0.branches(.local) }
            .map{ $0.count }
            .assertEqual(to: 2)
    }
    
    func test_branchCheckout() {
        let folder = root.sub(folder: "createBranch").cleared().shouldSucceed()!
        let src = folder.with(repo: "createBr", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url.appendingPathComponent("createBr") )
        
        src.repo
            .flatMap {  $0.createBranch(from: .HEAD, name: "anotherBr", checkout: false) }
            .shouldSucceed()
        
        /////// Checkout "anotherBr"
        
        let brId = BranchID(repoID: repoID, ref: "refs/heads/anotherBr")
        
        brId.checkout().shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/anotherBr")
        
        //////////////// Checkout "main"
        
        let brId2 = BranchID(repoID: repoID, ref: "refs/heads/main")
        
        brId2.checkout().shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/main")
    }
}
