import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

class FileChangesTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "FileChangesTests")
    
    func test_changes() {
        let folder = root.sub(folder: "Changes")
        let repo1 = folder.with(repo: "repo1", content: .clone(PublicTestRepo().urlSsh, CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault))))).repo.shouldSucceed("repo1 clone")!
        
        let filePath = "fileA.txt"
        
        // заважко будувати результат з блобів - треба вручну задавати шляхи і легко напартачити десь
//        let allCommits = repo1.commitsFromHead() .shouldSucceed("repo1 clone")!
//        let pairs = allCommits.map { commit in
//                commit
//                    .tree()
//                    .flatMap{ $0.entry(byPath: filePath) }
//                    .map { blob -> (Commit, Blob) in (commit, blob) }
//                    //.flatMapError{ blob -> R<(Commit, Blob)?> in .success(nil) }
//                    //.shouldSucceed("repo1 clone")!
//            }
        
        let allCommitsR = repo1.commitsFromHead()
        
        _ = allCommitsR.shouldSucceed("allCommitsR found")!
        
        let diffsR = allCommitsR.flatMap{ allCommits in
            allCommits.map { commit in
                repo1.deltas(target: .commit(commit.oid))
            }
            .flatMap{ $0 }
            .map { $0.map { $0.deltasWithHunks } }
        }
        .map{ $0.map{ $0.filter { $0.newFile?.path == filePath || $0.oldFile?.path == filePath  } } }
        
        _ = diffsR.shouldSucceed("diffsR found")!
        
        let changedsOfFileR = combine(allCommitsR, diffsR).map { commits, diffs -> Zip2Sequence<[Commit], [[Diff.Delta]]> in
            zip(commits, diffs)
        }
        .map{ $0.filter{ $0.1.count > 0 } }
        
        let changedsOfFile = changedsOfFileR.shouldSucceed("changedsOfFileR found")!
        
        XCTAssertTrue(changedsOfFile.count > 100, "changedsOfFile count is > 100")
        
        print("\r\r\r\r")
        print("-----------------------------------------------")
        print("commits with file changes FOUND: \(changedsOfFile.count)")
        print("-----------------------------------------------")
        print("\r\r\r\r")
    }
}
