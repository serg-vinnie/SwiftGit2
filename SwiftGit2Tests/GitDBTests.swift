
import XCTest
import SwiftGit2
import Essentials
import EssentialsTesting

final class GitDBTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "db")
    
    func test_status() {
        let folder = root.with(repo: "status", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        let diff = (repoID.headCommitID | { $0.diffToParent() })
            .shouldSucceed("diff")!.first!.diff
            
        XCTAssertEqual(diff.paths[TestFile.fileA.rawValue], .added)
        
        //
        // subf00/ -> subf01/  ->  [d.txt, e.txt]
        // a.txt      subf02/  ->  [f.txt, g.txt]
        // b.txt      c.txt
        
        let subf00 = folder.sub(folder: "subf00")
        let subf01 = subf00.sub(folder: "subf01")
        let subf02 = subf00.sub(folder: "subf02")
        
        folder.add(file: .fileB, content: .random).shouldSucceed()
        subf00.add(file: .fileC, content: .random).shouldSucceed()
        
        subf01.add(file: .fileD, content: .random).shouldSucceed()
        subf01.add(file: .fileE, content: .random).shouldSucceed()
        
        subf02.add(file: .fileF, content: .random).shouldSucceed()
        subf02.add(file: .fileG, content: .random).shouldSucceed()
        
        folder.addAllAndCommit(msg: "second commit")
        
        let diff2 = (repoID.headCommitID | { $0.diffToParent() })
            .shouldSucceed("diff 2")!.first!.diff
        
        print("subs \(diff2.folders.keys.count) :", diff2.folders.keys)
        XCTAssertEqual(diff2.folders.count, 3)
        XCTAssertEqual(diff2.folders["subf00"], [.added, .added, .added, .added, .added])
        XCTAssertEqual(diff2.folders["subf00/subf01"], [.added, .added])
        XCTAssertEqual(diff2.folders["subf00/subf02"], [.added, .added])
    }

    func test_extract() {
        let folder = root.with(repo: "objects", content: .commit(.fileA, .content1, "initial commit")).shouldSucceed()!
        let repoID = folder.repoID
        
        let subUrl = folder.url.appendingPathComponent("subFolder")
        _ = subUrl.makeSureDirExist()
        _ = subUrl.appendingPathComponent("fileB.txt").write(string: "bla-bla-bla")
        folder.addAllAndCommit(msg: "second commit")
            .shouldSucceed()
        
        let extract = root.url.appendingPathComponent("objects_extract")
        extract.rm().shouldSucceed()
        extract.makeSureDirExist().shouldSucceed()
        
        GitDB(repoID: repoID).trees
            .shouldSucceed("trees").asNonOptional
            .flatMap { $0.last.asNonOptional("last tree") }
            .flatMap { $0.extract(at: extract) }
            .shouldSucceed("extract")
        

        (GitDB(repoID: repoID).trees | { $0.hierarchy })
            .map { $0.roots.keys.map { $0.oid.oidShort } }
            .shouldSucceed("root")
    }
    


    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {

            // Put the code you want to measure the time of here.
        }
    }

}
