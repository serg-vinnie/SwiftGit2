import Essentials
@testable import SwiftGit2
import XCTest
import EssentialsTesting

class StatusDiffTests: XCTestCase {
    let root = TestFolder.git_tests.sub(folder: "StatusDiffTests")
        
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
        let folder = root.sub(folder: "should_return_content_of_Untracked_Staged_File").cleared().shouldSucceed()!
        _ = folder.clearRepo.flatMap { $0.t_with(file: .fileA, with: .oneLine1) }.shouldSucceed()
        
        var status = folder.repo
            .flatMap { $0.status() }
            .shouldSucceed("status")!
        
        let statusEntryHunks1 = folder.repo
            .flatMap{ status[0].with($0).hunks(options: DiffOptions()) }
            .shouldSucceed("statusEntryHunks1")!
        
        XCTAssert( statusEntryHunks1.staged.hunks.count == 0 && statusEntryHunks1.unstaged.hunks.count == 1 )
        
        folder.repo
            .flatMap { $0.stage(.all) }
            .shouldSucceed("stage(.all)")
        
        status = folder.repo
            .flatMap { $0.status() }
            .shouldSucceed("status")!
                
        XCTAssert(status.count == 1)
        XCTAssert(status[0].statuses.contains(.added))
        
        let statusEntryHunks2 = folder.repo
            .flatMap{ status[0].with($0).hunks(options: DiffOptions()) }
            .shouldSucceed("hunks")!
        
        XCTAssert( statusEntryHunks2.staged.hunks.count == 1 )
        
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
            case commit(Hunk)
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
    
//    func test_should_return_Hunk_From_File() {
//        root.with(repo: "shoudReturnHunk", content: .file(.fileA, .oneLine1))
//            .flatMap { $0.repo }
//            .flatMap{ $0.hunkFrom(relPath: TestFile.fileA.rawValue) }
//            .map { $0.lines[0].content }
//            .assertEqual(to: TestFileContent.oneLine1.rawValue, "hunk_0_line")
//    }
    
    func test_should_create_hooks_templates() {
        // TODO: implement me
    }
}
