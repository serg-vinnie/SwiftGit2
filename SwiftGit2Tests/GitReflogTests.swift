
import XCTest
@testable import SwiftGit2
import Essentials
import EssentialsTesting

final class GitReflogTests: XCTestCase {

    func testReflog() {
        let repo = Repository.at(path: "/Users/loki/dev/a")
        (repo | { $0.reflog(name: "HEAD") } | { $0.entryCount })
            .shouldSucceed("entry count")
        
//        reflog
    }
}
