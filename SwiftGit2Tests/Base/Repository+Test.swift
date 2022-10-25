
import Essentials
import Foundation
@testable import SwiftGit2
import XCTest

enum RepositoryContent {
    case empty
    case log(Int)
    case file(TestFile, TestFileContent)
    case commit(TestFile, TestFileContent, String)
    case clone(URL, CloneOptions)
}

extension Repository {
    func t_with(content: RepositoryContent) -> R<Repository> {
        switch content {
        case     .empty:                        return .success(self)
        case let .file  (file, content):        return t_with(file: file, with: content)
        case let .commit(file, content, msg):   return t_commit(file: file, with: content, msg: msg) | { _ in self }
        case .clone: fatalError("you shouldn't initiate clone from this place")
        case let .log(count):
            for i in 1...count {
                t_commit(file: .fileA, with: .random, msg: "commit \(i)")
                    .shouldSucceed()
                if i % 1000 == 0 {
                    print("\(i) commits generated")
                }
            }
            return .success(self)
        }
    }

    func t_push_commit(file: TestFile = .fileA, with content: TestFileContent = .oneLine1, msg: String) -> Result<Commit, Error> {
        t_commit(file: file, with: content, msg: msg)
            .flatMap { commit in self.push(.HEAD, options: PushOptions(auth: .credentials(.sshDefault))).map{ commit } }
    }

    func t_commit(file: TestFile = .fileA, with content: TestFileContent = .oneLine1, msg: String, signature: Signature = GitTest.signature) -> Result<Commit, Error> {
        t_write(file: file, with: content)
            .flatMap { file in self.addBy(path: file) }
            .flatMap { _ in self.commit(message: msg, signature: signature) }
    }
    
    func t_add_all_and_commit(msg: String) -> Result<Commit, Error> {
        let repo = self
        
        return repo.addAllFiles()
            .flatMap{ _ in
                repo.commit(message: msg, signature: GitTest.signature)
            }
        
    }
    
    func t_with_commit(file: TestFile, with content: TestFileContent, msg: String) -> R<Repository> {
        t_commit(file: file, with: content, msg: msg) | { _ in self }
    }

    func t_write(file: TestFile, with content: TestFileContent) -> Result<String, Error> {
        return t_with(file: file, with: content)
            .map { _ in file.rawValue }
    }
    
    func t_with(file: TestFile, with content: TestFileContent) -> R<Repository> {
        directoryURL
            .map { $0.appendingPathComponent(file.rawValue) }
            .flatMap { $0.write(content: content.get()) }
            .map { _ in self }
    }
}

enum TestFile: String {
    case fileA = "fileA.txt"
    case fileB = "fileB.txt"
    case fileC = "fileC.txt"
    case fileD = "fileD.txt"
    case fileLong = "pneumonoultramicroscopicsilicovolcanoconiosis.txt"
}

enum TestFileContent: String {
    case random
    case oneLine1
    case oneLine2

    case content1 = """
    01 The White Rabbit put on his spectacles.  "Where shall I begin,
    02 please your Majesty?" he asked.
    03
    04 "Begin at the beginning," the King said gravely, "and go on
    05 till you come to the end; then stop."
    06
    07
    08
    09
    """

    case content2 = """
    01 << LINE REPLACEMENT >>
    02 please your Majesty?" he asked.
    03
    04 "Begin at the beginning," the King said gravely, "and go on
    05 till you come to the end; then stop."
    06
    07
    08
    09
    10 << LINE INSERTION >>
    """
    
    case content3 = """
    01
    02
    03
    04
    05
    06
    07
    08
    09
    """
}

extension TestFileContent {
    func get() -> String {
        switch self {
        case .random:
            return UUID().uuidString
        default:
            return rawValue
        }
    }
}
