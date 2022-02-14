
import Foundation
import Essentials
import SwiftGit2
import EssetialTesting

extension TestFolder {
    var clearRepo        : R<Repository> { cleared() | { $0.repoCreate } }
    
    var repo             : R<Repository> { Repository.at(url: url) }
    var repoCreate       : R<Repository> { Repository.create(at: url) }
    var repoOpenOrCreate : R<Repository> {
        if Repository.exists(at: url) {
            return Repository.at(url: url)
        } else {
            return Repository.create(at: url)
        }
    }

    static var git_tests : TestFolder { TestFolder(url: URL.userHome.appendingPathComponent(".git_tests")) }
    
    @discardableResult
    func run<T>(_ block: (TestFolder)->R<T>) -> R<TestFolder> {
        block(self) | { _ in self }
    }
    
    @discardableResult
    func run<T>(_ topic: String? = nil, block: (TestFolder)->R<T>) -> R<TestFolder> {
        let r = block(self)
        
        
        if let _ = r.shouldSucceed(topic) {
            return .success(self)
        } else {
            return r | { _ in self }
        }
    }

    
    @discardableResult
    func run<T>(_ block: (TestFolder)->T) -> TestFolder {
        _ = block(self)
        return self
    }
}

extension TestFolder {
    func with(repo name: String, content: RepositoryContent) -> R<TestFolder> {
        let subFolder = sub(folder: name).cleared().shouldSucceed()!
        
        if case let .clone(url, options) = content {
            return Repository.clone(from: url, to: subFolder.url, options: options) | { _ in subFolder }
        } else {
            return subFolder.clearRepo | { $0.t_with(content: content) } | { _ in subFolder }
        }
    }
    
    func snapshoted(to folder: String) -> R<TestFolder> {
        let destination = url.deletingLastPathComponent().appendingPathComponent(folder)
        return url.copy(to: destination, replace: true) | { self }
    }
}

extension Result where Success == TestFolder, Failure == Error {
    var repo : R<Repository> {
        self.flatMap { $0.repo }
    }
    
//    @discardableResult
//    func run<T>(_ block: (TestFolder)->R<T>) -> R<TestFolder> {
//        self | { block($0).shouldSucceed() } | { _ in self }
//    }
    
    @discardableResult
    func run<T>(_ topic: String? = nil, _ block: (TestFolder)->T) -> R<TestFolder> {
        (self | { block($0) } | { _ in self }).verify(topic)
    }
    
    @discardableResult
    func run<T>(_ topic: String? = nil, block: (TestFolder)->R<T>) -> R<TestFolder> {
        self | { block($0).verify(topic) } | { _ in self }
    }
}
