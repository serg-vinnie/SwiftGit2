
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

extension RepoID {
    func t_commit(_ commit : TestCustomCommit) -> R<CommitID> {
        repo | { $0.t_commit(commit) } | { CommitID(repoID: self, oid: $0.oid) }
    }
    
    func t_commit(file: TestFile = .fileA, with content: TestFileContent = .oneLine1, msg: String, signature: Signature = GitTest.signature) -> R<Commit> {
        repo | { $0.t_commit(file: file, with: content, msg: msg, signature: signature) }
    }
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
    
    func t_commit(_ commit : TestCustomCommit) -> R<Commit> {
        self.t_with(files: commit.files)
            | { $0.stage(.all) }
            | { $0.commit(message: commit.msg, signature: commit.signature) }
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
    
    func t_with(files: [TestCustomFile]) -> R<Repository> {
        let urls = files.flatMap { self.t_write(file: $0) }
        return urls | { _ in self }
    }
    
    func t_write(file: TestCustomFile) -> R<URL> {
        if file.operation == .add {
            return directoryURL
                .map { $0.appendingPathComponent(file.path) }
                .flatMap { $0.write(content: file.content) }
        } else {
            return directoryURL
                .map { $0.appendingPathComponent(file.path) }
                .flatMap { url in url.rm() | { _ in url } }
        }
    }
}

struct TestCustomFile {
    enum Operation {
        case add
        case remove
    }
    
    let path: String
    let content : String
    let operation : Operation
    
    init(path: String, content: String? = nil, operation: Operation = .add) {
        self.path = path
        self.content = content ?? UUID().uuidString
        self.operation = operation
    }
    
    func renamed(path: String) -> TestCustomFile {
        return .init(path: path, content: content)
    }
    
    static var randomA : TestCustomFile { .init(path: TestFile.fileA.rawValue) }
    static var randomB : TestCustomFile { .init(path: TestFile.fileB.rawValue) }
    static var randomC : TestCustomFile { .init(path: TestFile.fileC.rawValue) }
    
    static var removeA : TestCustomFile { .init(path: TestFile.fileA.rawValue, operation: .remove) }
    static var removeB : TestCustomFile { .init(path: TestFile.fileB.rawValue, operation: .remove) }
    static var removeC : TestCustomFile { .init(path: TestFile.fileC.rawValue, operation: .remove) }
}

struct TestCustomCommit {
    let files : [TestCustomFile]
    let msg : String
    let signature: Signature
    
    init(files: [TestCustomFile], msg: String, signature: Signature = GitTest.signature) {
        self.files = files
        self.msg = msg
        self.signature = signature
    }
}

extension Array where Element == TestCustomCommit {
    func withNumbers() -> Self {
        var result = [TestCustomCommit]()
        var idx = 0
        for item in self {
            result.append(.init(files: item.files, msg: "⚽\(idx) " + item.msg , signature: item.signature))
            idx += 1
        }
        return result
    }
}

enum TestFile: String {
    case fileA = "fileA.txt"
    case fileB = "fileB.txt"
    case fileC = "fileC.txt"
    case fileD = "fileD.txt"
    case fileE = "fileE.txt"
    case fileF = "fileF.txt"
    case fileG = "fileG.txt"
    case fileH = "fileH.txt"
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
    
    case content4 = """
    01 I must not fear.
    02 Fear is the mind-killer.
    03 Fear is the little-death that brings total obliteration.
    04 I will face my fear.
    05 I will permit it to pass over me and through me.
    06 And when it has gone past I will turn the inner eye to see its path.
    07 Where the fear has gone there will be nothing.
    08 Only I will remain.
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
