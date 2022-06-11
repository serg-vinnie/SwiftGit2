import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

@available(macOS 10.15, *)
class CleanMyXcodeTests: XCTestCase {
    func test_GetWeightAndIsReacheble() {
        CleanMyXCode.shared.isGlobalDirsReacheble.assertEqual(to: true)
        
        let a = CleanMyXCode.shared.getWeight(of: CleanXcodeGlobal.derivedData.asUrl).shouldSucceed()!
        XCTAssertTrue( a > 0 )
        
        XCTAssertEqual(CleanXcodeGlobal.derivedData.asUrl.path,
                       "/Users/\(NSUserName())/Library/Developer/Xcode/DerivedData")
        XCTAssertEqual(CleanXcodeGlobal.deviceSupport.asUrl.path,
                       "/Users/\(NSUserName())/Library/Developer/Xcode/iOS DeviceSupport")
    }
    
    func test_XcodeIsRunned() {
        XCTAssertTrue(CleanMyXCode.shared.xcodeIsRunned)
    }
}
