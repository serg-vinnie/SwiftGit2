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
        Repository
            .at(url: urlHeadIsUnborn)
            .flatMap { $0.stage(.all) }
            .shouldSucceed()
        
        let status = Repository.at(url: urlHeadIsUnborn)
            .flatMap { $0.status() }
            .shouldSucceed()!
        XCTAssert(status.count == 1)
        XCTAssert(status[0].statuses.contains(.added))
        
        let hunks = Repository.at(url: urlHeadIsUnborn)
            .flatMap{ $0.hunksFrom(delta: status[0].stagedDeltas! ) }
            .shouldSucceed()!
        
        XCTAssert( hunks.count == 1 )
        
        let lines = hunks[0].lines.compactMap { $0.content}
        print(lines)
    }
    
    func test_should_create_hooks_templates() {
        // TODO: implement me
    }

    
}
