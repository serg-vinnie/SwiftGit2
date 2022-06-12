import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

@available(macOS 10.15, *)
class GitIgnoreTmpTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "StatusCustomTest")
    
    func test_workDirFilesIncludingIgnored() {
        let src = root.with(repo: "workDirFilesIncludingIgnored", content: .file(.fileA, .content1)).shouldSucceed()!
        
        try? File(url: src.url.appendingPathComponent(".gitignore") ).setContent("/ignoredDir/*")
        
        let ignoredDir = src.url.createSubDir(named: "ignoredDir").shouldSucceed()!
        
        src.addAllAndCommit(msg: "gitIgnore added")
        
        try? File(url: ignoredDir.appendingPathComponent("IGNORED_file1.txt") ).setContent("asdf1")
        try? File(url: ignoredDir.appendingPathComponent("IGNORED_file2.txt") ).setContent("asdf2")
        try? File(url: ignoredDir.appendingPathComponent("IGNORED_file3.txt") ).setContent("asdf3")
        
        try? File(url: src.url.appendingPathComponent("untrackedFile.txt") ).setContent("asdf4")
        
        src.addAll()
        
        let workDirFiles = src.repo.flatMap { $0.workDirFiles() }.shouldSucceed()!
        
        XCTAssertEqual(workDirFiles.count, 6) // Ignored x3 + .gitignore + fileA + untrackedFile.txt
        
        var unTrackedAndUnIgnoredFiles = src.repo.flatMap { $0.unTrackedAndUnIgnoredFiles() }.shouldSucceed()!
        XCTAssertEqual(unTrackedAndUnIgnoredFiles.count, 3)
        
        src.removeAll()
        unTrackedAndUnIgnoredFiles = src.repo.flatMap { $0.unTrackedAndUnIgnoredFiles() }.shouldSucceed()!
        
        XCTAssertEqual(unTrackedAndUnIgnoredFiles.count, 4)
        
        let unt = unTrackedAndUnIgnoredFiles.map{ $0.stagePath }
        
        XCTAssertTrue( unt.filter{ $0.contains("IGNORED_file1.txt") }.first != nil )
        XCTAssertTrue( unt.filter{ $0.contains("IGNORED_file2.txt") }.first != nil )
        XCTAssertTrue( unt.filter{ $0.contains("IGNORED_file3.txt") }.first != nil )
        XCTAssertTrue( unt.filter{ $0.contains("untrackedFile.txt") }.first != nil )
    }
}
