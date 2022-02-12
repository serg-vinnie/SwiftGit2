
import Essentials
import EssetialTesting
import Foundation
@testable import SwiftGit2
import XCTest

class RepositoryLocalTests: XCTestCase {
    let folder = TestFolder.git_tests.sub(folder: "RepositoryLocalTests")
    
    func test_DetachedHead() throws {
        let folder = self.folder.with(repo: "DetachedHead", content: .empty).shouldSucceed()!
        let repo = folder.repo.shouldSucceed()!
        
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
        
        guard let fixResultAmbigues = repo.detachedHeadFix().shouldSucceed("detached HEAD fix") else { fatalError() }
        
        XCTAssert(fixResultAmbigues == .ambiguous(branches: ["refs/heads/branch1", "refs/heads/main"]))
    }
}

extension Repository {
    func detachHEAD() -> Result<Void, Error> {
        HEAD()
            .flatMap { $0.targetOID }
            .flatMap { self.setHEAD_detached($0) }
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
