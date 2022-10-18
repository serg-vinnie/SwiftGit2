import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class GitStashTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "GitStashTests")
    
    func test_stashSaveAndStashList() {
        let folder = root.with(repo: "stashSave", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 2)
    }
    
    func test_stashLoad() {
        let folder = root.with(repo: "stashLoad", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        
        let stashItems = gitStash.items().shouldSucceed()!
        let stash = stashItems.first!
        
        gitStash.apply(stashIdx: stash.index).shouldSucceed()!
        
        XCTAssertEqual(stashItems.count, 1)
        gitStash.repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 2)
    }
    
    func test_stashRemove() {
        let folder = root.with(repo: "stashRemove", content: .commit(.fileA, .random, "asdf")).shouldSucceed()!
        
        let repoID = RepoID(url: folder.url )
        let gitStash = GitStash(repoID: repoID)
        
        createStash(folder: folder, gitStash: gitStash, expectedStashCount: 1)
        
        let firstStash = gitStash.items().shouldSucceed()!.first!
        
        gitStash.remove(stashIdx: firstStash.index).shouldSucceed()!
        
        let items = gitStash.items().shouldSucceed()!
        
        XCTAssertEqual(items.count, 0)
        repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0)
    }
    
    /*
     
     func test_shouldCloneWithSubmodule() {
         let folder = root.sub(folder: "Clone").cleared().shouldSucceed()!

         folder   .with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
             .with(submodule: "sub_repo",  content: .commit(.fileB, .random, "initial commit"))
             .shouldSucceed("addSub")
         
         let source = folder.sub(folder: "main_repo").url
         
         folder.with(repo: "clone", content: .clone(source, .defaultSSH))
             .flatMap { $0.repo | { $0.asModule } | { $0.updateSubModules(options: .local, init: true) } }
             .shouldSucceed("clone")
     }
     
     */
    
    func test_stasher_tag() {
        let folder = root.with(repo: "stasher_tag", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let repoID = RepoID(url: folder.url)
        
        (repoID.repo | { $0.t_write(file: .fileA, with: .random) })
            .shouldSucceed("t_write")
        
        let stasher = (repoID.repo | { GitStasher(repo: $0, state: .tag("tag")) }).maybeSuccess!
        
        stasher.push()
            .shouldSucceed()
        
        (GitStash(repoID: repoID).items() | { $0.first! })
            .map { $0.message! }
            .assertEqual(to: "On main: auto stash tag")
        
        //XCTAssert(stash.message == "auto stash tag")
    }
    
    func test_stasher() {
        //let folder = root.with(repo: "stasherEmptyRepo", content: .empty).shouldSucceed()!
        let folder = root.sub(folder: "stasher").cleared().shouldSucceed()!
        
        
        folder   .with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
            .with(submodule: "sub_repo",  content: .commit(.fileB, .random, "initial commit"))
            .shouldSucceed("addSub")
        
        let repoID = RepoID(url: folder.sub(folder: "main_repo").url )
        let subRepoID = RepoID(url: folder.sub(folder: "main_repo/sub_repo").url )

        let stasher = (repoID.repo | { GitStasher(repo: $0) }).maybeSuccess!
        
        stasher.push()
            .assertBlock("push") { $0.state == .empty }

        // write fileA
        (subRepoID.repo | { $0.t_write(file: .fileA, with: .random) })
            .shouldSucceed("t_write")

        stasher.push()
            .assertBlock("push2") { $0.state == .empty }


//
//        // commit
//        (repoID.repo | { $0.addAllFiles() } | { $0.commit(message: "initial commit", signature: .test) })
//            .shouldSucceed()
//
        // write fileA
        (repoID.repo | { $0.t_write(file: .fileA, with: .content1) })
            .shouldSucceed()

        // write fileB
        (repoID.repo | { $0.t_write(file: .fileB, with: .content2) })
            .shouldSucceed()

        // status.count == 3
        (repoID.repo | { $0.status() } | { $0.count })
            .assertEqual(to: 3)
//
//
//
        let stashed = stasher.push()
            .assertBlock("push") { $0.state.isStashed }
//
        // status.count == 1
        (repoID.repo | { $0.status() } | { $0.count })
            .assertEqual(to: 1)

        stashed!.pop()
            .map { $0.state }
            .assertEqual(to: .unstashed)

        let status = repoID.repo | { $0.status() }

        (status | { $0.count })
            .assertEqual(to: 3)

        let urlA = repoID.url.appendingPathComponent(TestFile.fileA.rawValue)
        let contentA = try! String(contentsOf: urlA)
        XCTAssertEqual(contentA, TestFileContent.content1.rawValue)

        let urlB = repoID.url.appendingPathComponent(TestFile.fileB.rawValue)
        let contentB = try! String(contentsOf: urlB)
        XCTAssertEqual(contentB, TestFileContent.content2.rawValue)

        (GitStash(repoID: repoID).items() | { $0.count })
            .assertEqual(to: 0)
    }

}

///////////////////////////////////
///HELPERS
///////////////////////////////////

fileprivate func createStash(folder: TestFolder, gitStash: GitStash, expectedStashCount: Int) {
    
    
    try? File(url: folder.urlOf(fileName: "file_1.txt")).setContent("file_1")
    try? File(url: folder.urlOf(fileName: "file_2.txt")).setContent("file_2")
    
    _ = gitStash.repoID.repo.map{ $0.stage(.all) }.shouldSucceed()!
    
    _ = gitStash.save(signature: .test, message: UUID().uuidString)
        .shouldSucceed()
    
    let stashItems = gitStash.items().shouldSucceed()!
    
    XCTAssertEqual(stashItems.count, expectedStashCount)
    gitStash.repoID.repo.flatMap { $0.status() }.map{ $0.count }.assertEqual(to: 0)
}
