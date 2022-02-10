
import Essentials
import EssetialTesting
import Foundation
@testable import SwiftGit2
import XCTest

class RepositoryLocalTests: XCTestCase {
    //    func test_measureStatus() {
    //        measure {
    //            Repository.at(path: "/Users/uks/dev/taogit")
    //                .flatMap{ $0.commitsIn(ref: "refs/heads/master") }
    //                .shouldSucceed()
    //        }
    //    }
    
    func testCreateOpenRepo() throws {
        GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .shouldSucceed("create repo")
    }
    
    func testCreateAddFile() throws {
        GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .flatMap { $0.t_commit(msg: "initial commit") }
            .shouldSucceed("initial commit")
    }
    
    func testCreateRepo() {
        let url = GitTest.localRoot.appendingPathComponent("NewRepo")
        let README_md = "README.md"
        url.rm().shouldSucceed("rm")
        
        guard let repo = Repository.create(at: url).shouldSucceed("Repository.create") else { fatalError() }
        
        let file = url.appendingPathComponent(README_md)
        "# test repository".write(to: file).shouldSucceed("write file")
        
        // if let status = repo.status().shouldSucceed("status") { XCTAssert(status.count == 1) } else { fatalError() }
        
        // repo.reset(paths: )
        repo.addBy(path: README_md)
        //index().flatMap { $0.add(paths: [README_md]) }
            .shouldSucceed("index add \(README_md)")
        
        repo.commit(message: "initial commit", signature: Signature(name: "name", email: "email@domain.com"))
            .shouldSucceed("initial commit")
    }
    
    func testDetachedHead() throws {
        let repo_ = GitTest.tmpURL
            .flatMap { Repository.create(at: $0) }
            .shouldSucceed("create repo")
        
        // for some reason it doesnt compile "let repo = repo"
        guard let repo = repo_ else { fatalError() }
        
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
