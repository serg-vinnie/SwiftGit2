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
    
    ///////////////////////////////////////////////////////
    ///RESOLVE FILE THEIR
    ///////////////////////////////////////////////////////
    func test_shouldResolveConflict_Their_File() {
        shouldResolveConflictFile( side: .their, folderName: "conflictResolveTheir")
    }
    
    func test_shouldResolveConflict_Our_File() {
        shouldResolveConflictFile( side: .our, folderName: "conflictResolveOur")
    }
    
    func test_shouldResolveConflict_MarkResolved_File() {
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
            .exist()
            .assertEqual(to: true)
        
        let path = TestFile.fileA.rawValue
        
        GitConflicts(repoID: repoID)
            .resolve(path: path, side: side, type: .file)
            .shouldSucceed("Conflict Resolved")
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
        
        switch side {
        case .our:
            repoID.url.appendingPathComponent(path).readToString
                .assertEqual(to: TestFileContent.oneLine2.rawValue)
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 0 }
                .assertEqual(to: true , "After --resolve as OUR-- must be 0 file with changes")
        case .their:
            repoID.url.appendingPathComponent(path).readToString
                .assertEqual(to: TestFileContent.oneLine1.rawValue)
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 1 }
                .assertEqual(to: true , "After --resolve as THEIR-- must be 1 file with changes")
            
        case .markAsResolved:
            repoID.url.appendingPathComponent(path).readToString
                .map{ $0.contains("||||||| ancestor") }
                .assertEqual(to: true, "Content is correct")
        }
        
    }
    /////////////////////////////////////////////////////
    
    
    ///////////////////////////////////////////////////////
    ///RESOLVE FILE OUR
    ///////////////////////////////////////////////////////
    func test_shouldResolveConflict_Our_Submod() {
        shouldResolveConflict_Submodule(side: .our, folderName:"Conflict_Submod_Resolve_Our")
    }
    
    func test_shouldResolveConflict_Their_Submod() {
        shouldResolveConflict_Submodule(side: .their, folderName:"Conflict_Submod_Resolve_Their")
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
        
        // update submodule in DST repo
        (dst.sub(folder: subRepo).repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .shouldSucceed()
        (dst.repo | { $0.addBy(path: subRepo) })
            .shouldSucceed()
        (dst.repo | { $0.commit(message: "update sub repo to commit 3", signature: .test) })
            .shouldSucceed()
        
        // ---------------------------------
        (dst.repo | { $0.pull(refspec: [], .HEAD, options: .local) })
            .shouldSucceed()
        
        let repoID = RepoID(url: dst.url )
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: true)
        
        GitConflicts(repoID: repoID)
            .resolve(path: subRepo, side: side, type: .submodule)
            .shouldSucceed("Conflict Resolved")
        
        GitConflicts(repoID: repoID)
            .exist()
            .assertEqual(to: false)
        
        switch side {
        case .our:
            // TODO:
            // Maybe we need to get oidStr from commit by some way? For comparation
            // let oidStr = OidRevFile(repo: repoID.repo.maybeSuccess!, type: .MergeHead).debugDescription
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 0 }
                .assertEqual(to: true , "After --resolve as OUR-- must be 0 file with changes")
            
            // sub_repo exists!
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo") )
                .shouldSucceed()
            
        case .their:
            // TODO:
            // Maybe we need to get oidStr from commit by some way? For comparation
            // let oidStr = OidRevFile(repo: repoID.repo.maybeSuccess!, type: .MergeHead).debugDescription
            
            repoID.repo
                .flatMap { $0.status() }
                .map { $0.count == 1 }
                .assertEqual(to: true , "After --resolve as THEIR-- must be 1 file with changes")
            
            // sub_repo exists!
            Repository.at(url: folder.url.appendingPathComponent("dst/sub_repo") )
                .shouldSucceed()
        case .markAsResolved:
            //Nothing to do
            break
        }
    }
}





extension MergeAnalysisTests {
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
