import Essentials
@testable import SwiftGit2
import XCTest
import EssetialTesting

class StatusDiffTests: XCTestCase {
    let urlRoot = URL.userHome.appendingPathComponent(".TaoTestData")
    lazy var urlHeadIsUnborn = urlRoot.appendingPathComponent("dst/headIsUnborn")
    lazy var urlOneCommit = urlRoot.appendingPathComponent("dst/oneCommit")
    
    override func setUp() {
        let dstURL = urlRoot.appendingPathComponent("dst")
        let srcURL = urlRoot.appendingPathComponent("src")
        srcURL.copy(to: dstURL, replace: true)
            .shouldSucceed()
    }
    
    func test_should_return_content_of_Untracked_Unstaged_File() {
        let status = Repository.at(url: urlHeadIsUnborn)
            .flatMap { $0.status() }
            .shouldSucceed()!
        XCTAssert(status.count == 1)
        XCTAssert(status[0].statuses.contains(.untracked))
        
        
    }
    
    func test_should_return_content_of_Untracked_Staged_File() {
        
    }
    
    func test_should_create_hooks_templates() {
        // TODO: implement me
    }

    
}
