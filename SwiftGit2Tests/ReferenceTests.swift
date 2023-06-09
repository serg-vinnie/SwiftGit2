import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

class ReferenceTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "Reference")
    
    func test_create_rename_branch() {
        let folder = root.with(repo: "create_rename", content: .commit(.fileA, .random, "")).shouldSucceed()!
        let repoID = folder.repoID
        
        GitReference(repoID).new(branch: "branch", from: .HEAD, checkout: false)
            .shouldSucceed()
        
        GitReference(repoID).list(.local)
            .map{ $0.count }
            .assertEqual(to: 2)
        
        ReferenceID(repoID: repoID, name: "refs/heads/branch")
            .rename("branch2")
            .shouldSucceed("rename")
        
        
    }
    
    func test_clone_rename_branch() {
        let folder = root.with(repo: "clone_rename", content: .clone(.testRepoSSH, .defaultSSH)).shouldSucceed()!
        let repoID = folder.repoID
        
        let refID = GitReference(repoID).new(branch: "test_branch", from: .HEAD, checkout: false)
            .shouldSucceed("create branch")!
        
        let sync = refID.createUpstream(in: .firstRemote, pushOptions: .init(auth: .defaultSSH))
            .shouldSucceed("createUpstream")!
        
        if case let .upstreamCreated(upstreamID) = sync {
            print(upstreamID)
            
            upstreamID.pushAsBranch(auth: .defaultSSH)
                .shouldSucceed("push")
            
            refID.delete()
                .shouldSucceed("delete")
            
            upstreamID
                .delete()
                .shouldSucceed("refID.delete")
            
            upstreamID.pushAsBranch(auth: .defaultSSH)
                .shouldSucceed("push after delete")
        }
        
        
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
