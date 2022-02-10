
import Foundation
import Essentials

struct TestFolder {
    let url : URL
    
    init(url: URL) {
        self.url = url
        _ = url.makeSureDirExist()
    }
    
    func sub(folder: String) -> TestFolder {
        TestFolder(url: self.url.appendingPathComponent(folder))
    }
    
    func cleared() -> R<URL> {
        url.rm() | { url.makeSureDirExist() }
    }
}

extension TestFolder {
    static var git_tests : TestFolder { TestFolder(url: URL.userHome.appendingPathComponent(".git_tests")) }
}
