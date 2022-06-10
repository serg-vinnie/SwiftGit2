import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

@available(macOS 10.15, *)
class CleanMyXcodeTests: XCTestCase {
    func test_GetWeightAndIsReacheble() {
        CleanMyXCode.shared.isGlobalDirsReacheble.assertEqual(to: true)
        
        for folderType in [CleanXcodeGlobal.derivedData, CleanXcodeGlobal.simulatorData] {
            let a = CleanMyXCode.shared.getWeight(of: folderType).shouldSucceed()!
            
            XCTAssertTrue( a > 0 )
            
            let txtToPrint = CleanMyXCode.shared.getWeightForHuman(of: folderType).shouldSucceed()!
            
            print("Human Readeble Weight: \(txtToPrint)")
        }
    }
    
    func test_XcodeIsRunned() {
        XCTAssertTrue(CleanMyXCode.shared.xcodeIsRunned)
    }
}
