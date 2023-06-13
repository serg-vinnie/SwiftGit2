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
        
        let upstreamID = refID.createUpstreamAt(remote: "origin", force: true)
                    .shouldSucceed("createUpstream")!
        
        refID.upstream
            .map { $0.name }
            .assertEqual(to: upstreamID.name, "upstream equal")
        
        upstreamID.push(auth: .defaultSSH, refspec: .onCreate)
            .shouldSucceed()
        
        let renamedRefID = refID.rename("test_branch_renamed", force: true)
            .shouldSucceed()!
        
        let renamedUpstreamID = upstreamID.rename("test_branch_renamed", force: true)
            .assertEqual(to: ReferenceID(repoID: repoID, name: "refs/remotes/origin/test_branch_renamed"))!
            //.shouldSucceed("upstream rename")!
        
        repoID.references.map { $0.map { $0.name } }
            .shouldSucceed("list")
        
        renamedRefID.upstream.map { $0.name }
            .assertEqual(to: renamedUpstreamID.name)
        
        upstreamID.push(auth: .defaultSSH, refspec: .onDelete)
            .shouldSucceed("push after delete")
        
        renamedUpstreamID.push(auth: .defaultSSH, refspec: .onCreate)
            .shouldSucceed("push renamed upstream")
        
        renamedUpstreamID.push(auth: .defaultSSH, refspec: .onDelete)
            .shouldSucceed("delete renamed upstream")
        
        repoID.references.map { $0.map { $0.name } }.shouldSucceed("refs")

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
