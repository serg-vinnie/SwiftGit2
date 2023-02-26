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
        let folder = root.with(repo: "checkout", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        let repoID = folder.repoID
        
        GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()
        
        let refID = ReferenceID(repoID: repoID, name: "refs/heads/branch")

        
        refID.checkout(options: CheckoutOptions(), stashing: false)
            .shouldSucceed()
        
        (repoID.HEAD | { $0.asReference } | { $0.name })
            .assertEqual(to: "refs/heads/branch")
        

        let mainID = ReferenceID(repoID: repoID, name: "refs/heads/main")
        
        mainID.checkout(options: CheckoutOptions(), stashing: false)
            .shouldSucceed()
        
        (repoID.HEAD | { $0.asReference } | { $0.name })
            .assertEqual(to: "refs/heads/main")
    }
}
