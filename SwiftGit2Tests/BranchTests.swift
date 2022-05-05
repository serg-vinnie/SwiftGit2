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
        
        let repoID = RepoID(url: root.url.appendingPathComponent("createBr") )
        
        src.repo
            .flatMap {  $0.createBranch(from: .HEAD, name: "anotherBr", checkout: false) }
            .shouldSucceed()
        
        let br = try! src.repo.flatMap{ $0.branchLookup(name: "refs/heads/anotherBr") }.get()
        let brId = br.asBranchId(repoID: repoID)
        
        brId.checkout().shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/anotherBr")
        
        //////////////// Checkout Main
        
        let br2 = try! src.repo.flatMap{ $0.branchLookup(name: "refs/heads/main") }.get()
        let brId2 = br.asBranchId(repoID: repoID)
        
        brId2.checkout().shouldSucceed()
        
        repoID.repo
            .flatMap { $0.headBranch() }
            .map { $0.nameAsReference }
            .assertEqual(to: "refs/heads/main")
    }
}
