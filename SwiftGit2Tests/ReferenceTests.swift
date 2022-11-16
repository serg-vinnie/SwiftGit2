import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ReferenceTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "Reference")
    
    func test_createBranch() {
        let folder = root.with(repo: "new", content: .commit(.fileA, .random, "")).shouldSucceed()!
        let repoID = folder.repoID
        
        GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()
        
        GitReference(repoID).list(.local)
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
        
        let brId = ReferenceID(repoID: repoID, name: "refs/heads/anotherBr")
        ////BranchID(repoID: repoID, ref: "refs/heads/anotherBr")
        
        brId.checkout(stashing: false).shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/anotherBr")
        
        //////////////// Checkout "main"
        
        let brId2 = ReferenceID(repoID: repoID, name: "refs/heads/main")
        //BranchID(repoID: repoID, ref: "refs/heads/main")
        
        brId2.checkout(stashing: false).shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/main")
    }
}
