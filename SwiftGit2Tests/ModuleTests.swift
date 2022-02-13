
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ModuleTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "ModuleTests")

    func test_moduleShouldNotExist() {
        (Repository.module(at: URL(fileURLWithPath: "some_shit")) | { $0.exists })
            .assertEqual(to: false, "module not exist")
    }
    
    func test_moduleShouldExists() {
        (root.with(repo: "moduleShouldExists", content: .empty)
            | { $0.repo }
            | { $0.asModule }
            | { $0.exists }
        ).assertEqual(to: true, "module exists")
    }
    
    func test_addRemote() {
        let folder = root.sub(folder: "AddRemote")
        let repoFolder = folder.with(repo: "repo", content: .empty).shouldSucceed()!
        
        repoFolder.snapshoted(to: "0_repo").shouldSucceed()
        
        repoFolder.repo
            .flatMap { $0.createRemote(url: PublicTestRepo().urlSsh.path) } // modifies .git/config
            .shouldSucceed("createRemote")
        
        repoFolder.snapshoted(to: "1_repo_with_remote").shouldSucceed()
    }
    
    func test_shouldCloneWithSubmodule() {
        let folder = root.sub(folder: "Clone")
        
        (folder.with(repo: "main_repo", content: .empty) | { $0.repo })
            .shouldSucceed()
        
        folder.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
    }
    
    func test_shouldAddAndCloneSubmodule2() {
        func cloneSubmoduleIn(repo: Repository) -> R<Repository> {
            let opt = SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.none)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
            return repo.submoduleLookup(named: "SubModule")
                .flatMap { $0.clone(options: opt) }
        }
        
        let folder = root.sub(folder: "AddSubmodule")
        
        folder.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
        
        folder.with(repo: "main_repo", content: .empty)
            .run { $0.snapshoted(to: "0_REPO_CLEAN") }
            .run { $0.repo | { $0.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true) } }
            .run { $0.snapshoted(to: "1_REPO_ADD_SUB") }
            .run { f in f.repo | { cloneSubmoduleIn(repo: $0) } | { _ in f } }
            .run { $0.snapshoted(to: "2_REPO_SUB_AFTER_CLONE") }
            .run { f in f.repo | { $0.submoduleLookup(named: "SubModule") | { $0.finalize() } } | { _ in f } }
            .run { $0.snapshoted(to: "3_REPO_SUB_AFTER_FINALIZE") }
            .shouldSucceed() //! as TestFolder
    }
    
    func test_shouldAddAndCloneSubmodule() {
        let folder = root.sub(folder: "AddSubmodule")
        let repo = (folder.with(repo: "main_repo", content: .empty) | { $0.repo })
            .shouldSucceed()!
        
        let folderMainRepo = folder.sub(folder: "main_repo")
        folderMainRepo.snapshoted(to: "0_REPO_CLEAN").shouldSucceed()
        
        folder.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
        
        // ADD
        //
        // + /.gitmodules
        // + .git/config:
        //
        //        [submodule "SubModule"]
        //            url = /Users/loki/.git_tests/ModuleTests/AddSubmodule/sub_repo
        //
        // [ gitlink: true ]
        // + .git/modules/SubModule
        // + /SubModule/.git: gitdir: ../.git/modules/SubModule/
        //
        // [ gitlink: false ]
        // + /SubModule/.git
        
        repo.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true)
            .shouldSucceed()
        
        folderMainRepo.snapshoted(to: "1_REPO_ADD_SUB").shouldSucceed()
        
        (repo.directoryURL | { $0.appendingPathComponent(".gitmodules").exists }) // file .gitmodules should exist
            .assertEqual(to: true)

        let submodule = repo.submoduleLookup(named: "SubModule").shouldSucceed()!
        XCTAssert(submodule.name == "SubModule")
        XCTAssert(submodule.path == "SubModule")
        XCTAssert(submodule.url == "../sub_repo")
        
        print("repoExists \(submodule.repoExist())")
        
        // CLONE
        let opt = SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.none)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
        
        submodule.clone(options: opt)
            .shouldSucceed()
        
        folderMainRepo.snapshoted(to: "2_REPO_SUB_AFTER_CLONE").shouldSucceed()
                
        // FINALIZE
        submodule.finalize()
            .shouldSucceed()
        
        folderMainRepo.snapshoted(to: "3_REPO_SUB_AFTER_FINALIZE").shouldSucceed()
    }

    func testPerformanceExample() throws {
        self.measure {
//            Repository.at(url: URL.userHome.appendingPathComponent("dev/taogit"))
//                .flatMap { $0.asModule }
//                .shouldSucceed()
        }
    }
}
