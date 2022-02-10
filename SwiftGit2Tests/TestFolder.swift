
import Foundation
import Essentials
import SwiftGit2

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


struct TestFolder {
    let url : URL
    
    init(url: URL) {
        self.url = url
        _ = url.makeSureDirExist()
    }
    
    func sub(folder: String) -> TestFolder {
        TestFolder(url: self.url.appendingPathComponent(folder))
    }
    
    func cleared() -> R<TestFolder> {
        url.rm() | { url.makeSureDirExist() } | { _ in self }
    }
}
