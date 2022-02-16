
import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class ModuleTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "ModuleTests")

    func test_submodules() {
        let url = URL.userHome.appendingPathComponent("dev/taogit")
        (Repository.module(at: url) | { $0.subModules } | { $0.count })
            .assertEqual(to: 3, "taogit submodules")
    }
    
//    func test_wtf() {
//        let repo = Repository.at(url: URL.userHome.appendingPathComponent("dev/taogit wtf"))
//        
//        (repo | { $0.status() } | { $0.count })
//            .shouldFail("status")
//
//        (repo | { $0.fixBrokenIndex() })
//            .shouldSucceed("fixBrokenIndex")
//
//        (repo | { $0.status() } | { $0.count })
//            .shouldSucceed("status")
//    }
    
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
    
    func test_addRemote1() {
        root.sub(folder: "AddRemote")
            .with(repo: "repo", content: .empty)
            .run { $0.snapshoted(to: "0_repo") }
            .run("createRemote") { $0.repo | { $0.createRemote(url: PublicTestRepo().urlSsh.path) } }
    }
    
    func test_shouldAddSubmoduleAndCommit() {
        let folder = root.sub(folder: "AddSub_And_Commit").cleared().shouldSucceed()!
        
        folder.with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
            .flatMap { $0.with(submodule: "sub_repo", content: .commit(.fileB, .random, "initial commit")) }
            .shouldSucceed("addSub")
        
        (folder.sub(folder: "main_repo").repo | { $0.status() } | { $0.count })
            .assertEqual(to: 0, "no files in workdir")
        
        (folder.sub(folder: "main_repo").repo | { $0.asModule } | { $0.subModules.count })
            .assertEqual(to: 1, "one sub module should exists")
    }
    
    func test_shouldAddSubmoduleAnd_NotCommit() {
        let folder = root.sub(folder: "AddSub_And_NotCommit").cleared().shouldSucceed()!
        
        folder.with(repo: "main_repo", content: .file(.fileA, .random))
            .flatMap { $0.with(submodule: "sub_repo", content: .commit(.fileB, .random, "initial commit")) }
            .shouldSucceed()
        
        (folder.sub(folder: "main_repo").repo | { $0.status() } | { $0.count })
            .assertEqual(to: 3, "3 files in workdir")
    }
            
    func test_shouldCloneWithSubmodule() {
        let folder = root.sub(folder: "Clone").cleared().shouldSucceed()!

        folder   .with(repo: "main_repo", content: .commit(.fileA, .random, "initial commit"))
            .with(submodule: "sub_repo",  content: .commit(.fileB, .random, "initial commit"))
            .shouldSucceed("addSub")
        
        let source = folder.sub(folder: "main_repo").url
        
        folder.with(repo: "clone", content: .clone(source, .defaultSSH))
            //.flatMap { $0.repo | { $0.asModule } | { $0.updateSubModules() } }
            .shouldSucceed("clone")
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
