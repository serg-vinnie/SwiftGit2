import Essentials
@testable import SwiftGit2
import XCTest
import EssentialsTesting

class MergeAnalysisTests: XCTestCase {
    let root  = TestFolder.git_tests.sub(folder: "MergeAnalysisTests")
    
    func test_branchSync() {
        let folder = root.sub(folder: "branchSync").cleared().shouldSucceed()!
        
        let remote = folder.with(repo: "our", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        let local = folder.with(repo: "their", content: .clone(remote.url, .local)).shouldSucceed()!
        
        remote.commit(file: .fileA, with: .random, msg: "Commit 2").shouldSucceed()
        remote.commit(file: .fileB, with: .random, msg: "Commit 3").shouldSucceed()
        
        local.fetchHead(options: .local).shouldSucceed()
        
        let our = ReferenceID(repoID: local.repoID, name: "refs/heads/main")
        let their = ReferenceID(repoID: local.repoID, name: "refs/remotes/origin/main")
        
        var branchSync = BranchSync.with(our: our, their: their)
            .shouldSucceed()!
        
        XCTAssert(branchSync.pull.maybeSuccess?.count == 2)
        XCTAssert(branchSync.push.maybeSuccess?.count == 0)
        
        local.commit(file: .fileA, with: .random, msg: "Commit 2").shouldSucceed()
        local.commit(file: .fileC, with: .random, msg: "Commit 3").shouldSucceed()
        
        branchSync = BranchSync.with(our: our, their: their)
            .shouldSucceed()!
        
        XCTAssert(branchSync.pull.maybeSuccess?.count == 2)
        XCTAssert(branchSync.push.maybeSuccess?.count == 2)
        
        let index = branchSync.mergeIndex.shouldSucceed()!
        
        index.conflicts()
            .map { $0.count }
            .assertEqual(to: 1)
        
        let entries = index.entries().shouldSucceed()!
        
        for entry in entries {
            print(entry.path)
        }
        //XCTAssertEqual(index.entrycount, 3)
    }
    
    func test_shouldMergeFastForward() {
        let folder = root.sub(folder: "fastForward").cleared().shouldSucceed()!
        
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "Commit 1")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        src.commit(file: .fileA, with: .random, msg: "Commit 2").shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .upToDate)
        
        dst.fetchHead(options: .local).shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: [.fastForward, .normal])
        
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .assertEqual(to: .fastForward, "pull fast forward merge")
    }
    
    func test_shouldMergeThreeWay() {
        let folder = root.sub(folder: "threeWay").cleared().shouldSucceed()!
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        src.commit(file: .fileA, with: .random, msg: "File A").shouldSucceed()
        dst.commit(file: .fileB, with: .random, msg: "File B").shouldSucceed()
        
        dst.fetchHead(options: .local).shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .normal)
        
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .assertEqual(to: .threeWaySuccess, "Pull")
    }
    
    func test_mergeTree() {
        let folder = root.with(repo: "mergeTree", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        let refID = GitReference(repoID).new(branch: "branch", from: .HEAD , checkout: false)
            .shouldSucceed()!
        let mainID = ReferenceID(repoID: repoID, name: "refs/heads/main")
        
        folder.commit(file: .fileB, msg: "commit from main")
            .shouldSucceed()
        
        refID.checkout(options: CheckoutOptions())
            .shouldSucceed()
        
        folder.commit(file: .fileB, msg: "commit from branch")
            .shouldSucceed()
        
        refID.checkout(options: CheckoutOptions())
            .shouldSucceed()
        
        GitMergeTree(src: .reference(mainID), dst: refID)
            .rows
            .map { "\n\n" + $0.map { $0.description }.joined(separator: "\n") }
            .shouldSucceed("rows")
    }
    
    func test_shoulConflict() {
        let folder = root.sub(folder: "conflict").cleared().shouldSucceed()!
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        src.commit(file: .fileA, with: .random, msg: "File A").shouldSucceed()
        dst.commit(file: .fileA, with: .random, msg: "File A").shouldSucceed()
        
        dst.fetchHead(options: .local).shouldSucceed()
        
        (dst.repo | { $0.mergeAnalysisUpstream(.HEAD) })
            .assertEqual(to: .normal)
        
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .map { $0.hasConflict }
            .assertEqual(to: true, "Pull has conflict")
    }
}

///
/// RESOLVE FILE
///
extension MergeAnalysisTests {
    func test_shouldResolveConflict_File_Our() {
        shouldResolveConflictFile( side: .our, folderName: "conflictResolveOur")
    }
    
    func test_shouldResolveConflict_File_Their() {
        shouldResolveConflictFile( side: .their, folderName: "conflictResolveTheir")
    }
    
    func test_shouldResolveConflict_File_MarkResolved() {
        shouldResolveConflictFile( side: .markAsResolved, folderName: "conflictResolveMarkResolved")
    }
    
    func shouldResolveConflictFile(side: ConflictSide, folderName: String) {
        let folder = root.sub(folder: folderName)
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "initial commit")).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        src.commit(file: .fileA, with: .oneLine1, msg: "File A").shouldSucceed()
        dst.commit(file: .fileA, with: .oneLine2, msg: "File A").shouldSucceed()
        
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .shouldSucceed()
        
        // -------------------------------------------------------------------
        
        let repoID = dst.repoID
        
        GitConflicts(repoID: repoID)
            .all()
            .map{ $0.count }
            .assertEqual(to: 1)
        
        let path = TestFile.fileA.fileName
        
        GitConflicts(repoID: repoID)
            .resolve(path: path, side: side, type: .file)
            .shouldSucceed("Conflict Resolved")
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
        
        switch side {
        case .our:
            repoID.url.appendingPathComponent(path).readToString
                .assertEqual(to: TestFileContent.oneLine2.content)
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 0 }
                .assertEqual(to: true , "After --resolve as OUR-- must be 0 file with changes")
        case .their:
            repoID.url.appendingPathComponent(path).readToString
                .assertEqual(to: TestFileContent.oneLine1.content)
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 1 }
                .assertEqual(to: true , "After --resolve as THEIR-- must be 1 file with changes")
            
        case .markAsResolved:
            repoID.url.appendingPathComponent(path).readToString
                .map{ $0.contains("<<<<<<<") || $0.contains("|||||||") }
                .assertEqual(to: true, "Content is correct")
        }
        
    }
}

///
/// RESOLVE FILE ADVANCED
///
extension MergeAnalysisTests {
    
    //should fail, this is OK
    func test_shouldResolveConflictAdvanced_File_Our_swifGit2() {
        shouldConflictFileAdvanced(side: .our,   folderName: "conflictAdvancedResolveSG2Our", merge3way: .swiftGit2)
    }
    
    //should fail, this is OK
    func test_shouldResolveConflictAdvanced_File_Their_swifGit2() {
        shouldConflictFileAdvanced(side: .their, folderName: "conflictAdvancedResolveSG2Their", merge3way: .swiftGit2)
    }
    
    func test_shouldResolveConflictAdvanced_File_Our_cli() {
        shouldConflictFileAdvanced(side: .our,   folderName: "conflictAdvancedResolveCliOur", merge3way: .cli)
    }
    
    func test_shouldResolveConflictAdvanced_File_Their_cli() {
        shouldConflictFileAdvanced(side: .their, folderName: "conflictAdvancedResolveCliTheir", merge3way: .cli)
    }
    
    func shouldConflictFileAdvanced(side: ConflictSide, folderName: String, merge3way: MergeThreeWay) {
        let folder = root.sub(folder: folderName)
        let src = folder.with(repo: "src", content: MergeTemplates.c1_our.asRepoContent).shouldSucceed()!
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local)).shouldSucceed()!
        
        src.url.appendingPathComponent("Ifrit/LevenstAin").path.FS.delete()
            .shouldSucceed()
        src.repo.flatMap{ $0.stage(.all) }.shouldSucceed()
        src.commit(file: MergeTemplates.c2_our.asTestFile, with: MergeTemplates.c2_our.asTestFileContent, msg: "bebebeSrc").shouldSucceed()
        
        dst.url.appendingPathComponent("Ifrit/LevenstAin").path.FS.delete()
            .shouldSucceed()
        dst.repo.flatMap{ $0.stage(.all) }.shouldSucceed()
        dst.commit(file: MergeTemplates.c3_their.asTestFile, with: MergeTemplates.c3_their.asTestFileContent, msg: "bebebeDst").shouldSucceed()
        
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local, merge3way: merge3way ) })
            .shouldSucceed()
        
        // Advanced conflict created here
        
        let repoID = dst.repoID
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
        
        let conflicts = GitConflicts(repoID: repoID)
            .all()
            .maybeSuccess!
        
        XCTAssertEqual(conflicts.count, 1)
        
        GitConflicts(repoID: repoID)
            .resolve(path: "Ifrit/LevenstEin/LevenstEin.swift", side: side, type: .file)
            .shouldSucceed()
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
        
        //
        // It's OK that it's failing now, but need to fix in future
        //
        //        діскард що я реалізував після резолва конфлікта asOur в певних ситуаціях залишає ось таку папочку (не завжди)
        //        я боюсь її автоматично ремувити з індекса - тому що в теорії там можуть законфліктитися декілька файлів по подібній схемі і якщо я автоматом його приберу - я не знаю які в цього будуть наслідки для індекса/репозиторія.
        //
        //        Тут 2 варіанти:
        //        * Це рідкісна ситуація тож надаємо юзеру необхідність зробити зайвий клік самостійно і не ліземо
        //        * написати на це окремий тест і потім написати функціонал автоматичного безпечного уникнення даної ситуації. На це може піти спокійно ще пів дня.
        //
        //        Я вважаю що 2й варіант нерезонний і ліпше підемо першим варіком.
        let repoEntries = dst.repoID.repo.flatMap{ $0.status() }.map{ $0.filter { $0.stagePath == "Ifrit/" } }.maybeSuccess!
        XCTAssertFalse(repoEntries.count == 1)
    }
}

///
/// RESOLVE SUBMODULE OUR
///
extension MergeAnalysisTests {
    func test_shouldResolveConflict_Submod_Our() {
        shouldResolveConflict_Submodule(side: .our, folderName:"Conflict_Submod_Resolve_Our")
    }
    
    func test_shouldResolveConflict_Submod_Their() {
        shouldResolveConflict_Submodule(side: .their, folderName: "Conflict_Submod_Resolve_Their")
    }
    
    func shouldResolveConflict_Submodule(side: ConflictSide, folderName: String) {
        let folder = root.sub(folder: folderName)
        let subRepo = "sub_repo"
        
        // create repo with submodule
        let src = folder.with(repo: "src", content: .commit(.fileA, .random, "src commit 1"))
            .flatMap { $0.with(submodule: "sub_repo", content: .commit(.fileB, .random, "sub commit 1")) }
            .shouldSucceed("addSub")!
        
        // clone repo
        let dst = folder.with(repo: "dst", content: .clone(src.url, .local))
            .shouldSucceed()!
        
        (dst.repo | { $0.asModule } | { $0.updateSubModules(options: .local, init: true) } )
            .shouldSucceed()!
        
        // create commit #2 in sub_repo
        (folder.sub(folder: subRepo).repo | { $0.t_commit(file: .fileB, with: .random, msg: "sub commit 2") })
            .shouldSucceed()
        
        // update submodule in SRC repo
        (src.sub(folder: subRepo).repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .shouldSucceed()
        (src.repo | { $0.addBy(path: subRepo) })
            .shouldSucceed()
        (src.repo | { $0.commit(message: "update sub repo to commit 2", signature: .test) })
            .shouldSucceed()
        
        // create commit #3 in sub_repo
        (folder.sub(folder: subRepo).repo | { $0.t_commit(file: .fileB, with: .random, msg: "sub commit 3") })
            .shouldSucceed()
        
        // make head NOT detached to be able to update submodule
        (dst.sub(folder: subRepo).repo.flatMap) { $0.detachedHeadFix() }
            .shouldSucceed()
        
        // update submodule in DST repo
        (dst.sub(folder: subRepo).repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .shouldSucceed()
        (dst.repo | { $0.addBy(path: subRepo) })
            .shouldSucceed()
        (dst.repo | { $0.commit(message: "update sub repo to commit 3", signature: .test) })
            .shouldSucceed()
        
        // must be "merge3way: .swiftGit2"
        // because of .cli version do automerge of submodule by latest date/time
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local, merge3way: .swiftGit2) })
            .shouldSucceed()
        
        let repoID = RepoID(url: dst.url )
        
        // can be nil if you used .cli version of pull
        let oidOur   = GitConflicts(repoID: repoID).getOIDForSubmoduleConflict(path: subRepo, side: .our).maybeSuccess!
        // can be nil if you used .cli version of pull
        let oidTheir = GitConflicts(repoID: repoID).getOIDForSubmoduleConflict(path: subRepo, side: .their).maybeSuccess!
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
        
        // now conflict exist
        
        GitConflicts(repoID: repoID)
            .resolve(path: subRepo, side: side, type: .submodule)
            .shouldSucceed("Conflict Resolved")
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
        
        switch side {
        case .markAsResolved:
            fallthrough
        case .our:
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 0 }
                .assertEqual(to: true , "After --resolve as OUR-- must be 0 file with changes")
            
            // sub_repo exists!
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo") )
                .shouldSucceed()
            
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo"))
                .flatMap {
                    $0.headCommit()
                }
                .map{ $0.oid }
                .assertEqual(to: oidOur)
            
        case .their:
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 1 }
                .assertEqual(to: true , "After --resolve as THEIR-- must be 1 file with changes")
            
            // sub_repo exists!
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo") )
                .shouldSucceed()
            
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo"))
                .flatMap {
                    $0.headCommit()
                }
                .map{ $0.oid }
                .assertEqual(to: oidTheir)
        }
    }
}



//
// Helpers
//

fileprivate extension MergeAnalysisTests {
    private func createConflict(subFolder: String) -> TestFolder {
        let folder = root.sub(folder: subFolder)
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, .ssh)).repo.shouldSucceed("repo1 clone")!
        let repo2 = folder.with(repo: "repo2", content: .clone(PublicTestRepo().urlSsh, .ssh)).repo.shouldSucceed("repo2 clone")!
        
        // fileA
        repo2.t_push_commit(file: .fileLong, with: .random, msg: "[THEIR] for THREE WAY SUCCESSFUL MERGE test")
                   .shouldSucceed()
        
        // Same fileA
        repo1.t_commit(file: .fileLong, with: .random, msg: "[OUR] for THREE WAY **SUCCESSFUL** MERGE test")
            .shouldSucceed()
        
        repo1.fetch(refspec: [], .HEAD, options: FetchOptions(auth: .credentials(.sshDefault)))
            .shouldSucceed()
        
        let merge = repo1.mergeAnalysisUpstream(.HEAD)
            .assertNotEqual(to: [.fastForward])
        
        XCTAssert(merge == .normal)
        
        let options = PullOptions(signature: GitTest.signature, fetch: FetchOptions(auth: .credentials(.sshDefault)))
        
        repo1.pull(refspec: [], .HEAD, options: options)
            .map { $0.hasConflict }
            .assertEqual(to: true)
        
        return folder
    }
}
