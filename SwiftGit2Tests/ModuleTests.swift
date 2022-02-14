
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
    
    func test_addRemote2() {
        root.sub(folder: "AddRemote")
            .with(repo: "repo", content: .empty)
            .run { $0.snapshoted(to: "0_repo") }
            .run("createRemote") { $0.repo | { $0.createRemote(url: PublicTestRepo().urlSsh.path) } }
            
    }
            
    func test_shouldCloneWithSubmodule() {
        let folder = root.sub(folder: "Clone").cleared().shouldSucceed()!
        
//        let sub_remote = "git@github.com:serg-vinnie/SwinjectAutoregistration.git"
        
        folder.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()

        folder.with(repo: "main_repo", content: .empty)
            .run { Repository.module(at: $0.url) | { $0.addSub(module: "SubModule", remote: "../sub_repo", gitlink: true, options: .defaultSSH) } }
            .shouldSucceed("addSub")
        
    }
    
    func test_shouldAddAndCloneSubmodule() {
        func cloneSubmoduleIn(repo: Repository) -> R<Repository> {
            return repo.submoduleLookup(named: "SubModule")
                .flatMap { $0.clone(options: .defaultSSH) }
        }
        
        let folder = root.sub(folder: "AddSubmodule").cleared().shouldSucceed()!
        
        folder.with(repo: "sub_repo", content: .commit(.fileA, .random, "initial commit"))
            .shouldSucceed()
        
        folder.with(repo: "main_repo", content: .empty)
            .run { $0.snapshoted(to: "0_REPO_CLEAN") }
            .run { $0.repo | { $0.add(submodule: "SubModule", remote: "../sub_repo", gitlink: true).flatMap { $0.clone(options: .defaultSSH).verify("CLONE") } } }
            .run { $0.snapshoted(to: "1_REPO_ADD_SUB") }
            
            .run {
                ($0.repo.flatMap { $0.directoryURL }.map { $0.appendingPathComponent(".gitmodules").exists })
                    .assertEqual(to: true)

                let submodule = ($0.repo | { $0.submoduleLookup(named: "SubModule") }).shouldSucceed()!
                //print(submodule.absURL)
                XCTAssert(submodule.name == "SubModule")
                XCTAssert(submodule.path == "SubModule")
                XCTAssert(submodule.url == "../sub_repo")
                XCTAssert(!submodule.repoExist())
            }
            .run { $0.repo | { cloneSubmoduleIn(repo: $0) } }
            .run { $0.snapshoted(to: "2_REPO_SUB_AFTER_CLONE") }
            .run { $0.repo | { $0.submoduleLookup(named: "SubModule") | { $0.add_finalize() } } }
            .run { $0.snapshoted(to: "3_REPO_SUB_AFTER_FINALIZE") }
        // commit
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
        
        // CLONE

        // FINALIZE
    }

    func testPerformanceExample() throws {
        self.measure {
//            Repository.at(url: URL.userHome.appendingPathComponent("dev/taogit"))
//                .flatMap { $0.asModule }
//                .shouldSucceed()
        }
    }
}
