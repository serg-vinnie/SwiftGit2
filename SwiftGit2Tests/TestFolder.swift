
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
        let subFolder = sub(folder: name)
        return subFolder.clearRepo | { _ in subFolder }
    }
}
