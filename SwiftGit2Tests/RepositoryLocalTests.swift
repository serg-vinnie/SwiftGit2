import Essentials
import EssentialsTesting
import Foundation
@testable import SwiftGit2
import XCTest

class RepositoryLocalTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "RepositoryLocalTests")
    
//    func test_deltas_measure() {
//        //let url =
//        let repoID = RepoID(url: URL.userHome.appendingPathComponent("dev/z-ua.com"))
//
//        self.measure {
//            (repoID.repo | { $0.deltas(target: .commit(OID(string: "719c6fb2b8d9dee5b9ee94e852ee03f7f2ea85ea")!), findOptions: []) })
//                .shouldSucceed()
//        }
//    }
    
    func test_DetachedHead() throws {
        let folder = self.root.with(repo: "DetachedHead", content: .empty).shouldSucceed()!
        let repo = folder.repo.shouldSucceed()!
        let repoID = folder.repoID
        
        // HEAD is unborn
        XCTAssert(repo.headIsUnborn)
        guard let fixResultUnborn = repo.detachedHeadFix().shouldSucceed("detached HEAD fix on unborn") else { fatalError() }
        XCTAssert(fixResultUnborn == .notNecessary)
        
        // single commit
        repo.t_commit(msg: "commit1").shouldSucceed("commit")
        XCTAssert(!repo.headIsUnborn)
        guard let fixResultWCommit = repo.detachedHeadFix().shouldSucceed("detached HEAD fix on commit1") else { fatalError() }
        XCTAssert(fixResultWCommit == .notNecessary)
        
        repo.detachHEAD()
            .shouldSucceed("set HEAD detached")
        
        guard let fixResultDetached = repo.detachedHeadFix().shouldSucceed("detached HEAD fix") else { fatalError() }
        XCTAssert(fixResultDetached == .fixed)
        
        repo.createBranch(from: .HEAD, name: "branch1", checkout: false)
            .shouldSucceed("create branch1")
        
        repo.detachHEAD()
            .shouldSucceed("set HEAD detached")
        
        guard let fixResultAmbigues = repo.detachedHeadFix()
            .shouldSucceed("detached HEAD fix") else { fatalError() }
        
        XCTAssert(fixResultAmbigues == .ambiguous(branches:
                                                    [ReferenceID(repoID: repoID, name: "refs/heads/branch1"),
                                                     ReferenceID(repoID: repoID, name: "refs/heads/main")]))
    }
}

extension Repository {
    func detachHEAD() -> R<Void> {
        repoID | { $0.HEAD } | { $0.detach() }
    }
}

////HELPERS
extension Repository {
    func commitsIn(range: String) -> R<[Commit]> {
        let oids = Revwalk.new(in: self) | { $0.push(range: range) } | { $0.all() }
        return oids.flatMap { $0.flatMap { self.commit(oid: $0) } }
    }
    
    func commitsIn(ref: String) -> R<[Commit]> {
        let oids = Revwalk.new(in: self) | { $0.push(ref: ref) } | { $0.all() }
        return oids.flatMap { $0.flatMap { self.commit(oid: $0) } }
    }
}
