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
    
//    func test_should_return_content_of_Untracked_Unstaged_File() {
//        let repo = Repository.at(url: urlHeadIsUnborn)
//            .shouldSucceed()!
//
//        let status = Repository.at(url: urlHeadIsUnborn)
//            .flatMap { $0.status() }
//            .shouldSucceed()!
//        XCTAssert(status.count == 1)
//        XCTAssert(status[0].statuses.contains(.untracked))
//
//    }
    
    func test_should_return_content_of_Untracked_Staged_File() {
        var status = Repository.at(url: urlHeadIsUnborn)
            .flatMap { $0.status() }
            .shouldSucceed()!
        
        let statusEntryHunks1 = Repository
            .at(url: urlHeadIsUnborn)
            .flatMap{ status[0].hunks(repo: $0 ) }
            .shouldSucceed()!
        
        XCTAssert( statusEntryHunks1.staged.count == 0 && statusEntryHunks1.unstaged.count == 1 )
        
        Repository
            .at(url: urlHeadIsUnborn)
            .flatMap { $0.stage(.all) }
            .shouldSucceed()
        
        status = Repository.at(url: urlHeadIsUnborn)
            .flatMap { $0.status() }
            .shouldSucceed()!
        XCTAssert(status.count == 1)
        XCTAssert(status[0].statuses.contains(.added))
        
        let statusEntryHunks2 = Repository.at(url: urlHeadIsUnborn)
            .flatMap{ status[0].hunks(repo: $0 ) }
            .shouldSucceed()!
        
        XCTAssert( statusEntryHunks2.staged.count == 1 )
        
//        let lines = hunks[0].lines.compactMap { $0.content}
//        print(lines)
//
        //+++++++++++++++++++++++++++++
        // 2
        // (staged + unstaged).sorted()
        
        // 3
        // mixed hunks
        
        // ---------------------------------------------------------
        
        // test repos wtih mixed state:
        // 1. normal hunks (no mixed state)
        // 2. mixed hunks
        
        // --------------------------------------------------------- BASIC
        
        // hunk.print()
        //
        
        /*
                             //+++++++++++++++++++++++++++++
                             struct StatusEntryHunks {
                                let staged : [Hunk] //dir
                                let unstaged : [Hunk] //dir
                             }
                             //+++++++++++++++++++++++++++++
                             extenstion StatusEntryHunks {
                                var all : [Hunk] {
                                    
                                }
                             }
         
                             //+++++++++++++++++++++++++++++
                             let statusEntryHunks = repo.hunksIn(entry: status[0]) -> StatusEntryHunks
         
         statusEntryHunks.all.map { $0.asHTML }
         statusEntryHunks.all.map { $0.asString }
         
         */
        
        // --------------------------------------------------------- MIXED STATE
        
        /*
         
         enum StatusEntryHunkEntry {
            case staged(Hunk)
            case unstaged(Hunk)
            case mixed(Hunk,Hunk)
         }
         
         extenstion StatusEntryHunks {
            var allEntries : [StatusEntryHunkEntry] {
                
            }
         }
         
         extension StatusEntryHunkEntry {
            var asString : String { get }
            var asHTML  : Strinng { get }
            var asAttributedString : NSAttributedString { get }
         }
         
         extension NSAttributedString {
            var asHTML :  String
         }
         
         */
        
        // --------------------------------------------------------- patch per hunk
        
        /*
         
            
         
         */
    }
    
    func test_should_return_Hunk_From_File() {
        let hunk = Repository.at(url: urlHeadIsUnborn)
            .flatMap{ $0.hunkFrom(relPath: "file.txt") }
            .shouldSucceed("hunk")!
        
        print(hunk.lines.map{ $0.content} )
        
        XCTAssert(hunk.lines[0].content == "bla bla bla\n")
    }
    
    func test_should_create_hooks_templates() {
        // TODO: implement me
    }
}
