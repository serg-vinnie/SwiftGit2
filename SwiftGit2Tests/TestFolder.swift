
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
    
    func snapshot(to folder: String) -> R<URL> {
        let destination = url.deletingLastPathComponent().appendingPathComponent(folder)
        return url.copy(to: destination, replace: true) | { destination }
    }
}

extension Result where Success == TestFolder, Failure == Error {
    var repo : R<Repository> {
        self.flatMap { $0.repo }
    }
}
