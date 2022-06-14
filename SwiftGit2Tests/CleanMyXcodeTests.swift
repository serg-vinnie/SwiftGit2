import XCTest
import SwiftGit2
import Essentials
import EssetialTesting

@available(macOS 10.15, *)
class CleanMyXcodeTests: XCTestCase {
    
    func test_urlsIsCorrect() {
        XCTAssertEqual( CleanMyXCode.GlobalDerivedData.url.path,         "/Users/\(NSUserName())/Library/Developer/Xcode/DerivedData")
        XCTAssertEqual( CleanMyXCode.GlobalDeviceSupport.url.path,       "/Users/\(NSUserName())/Library/Developer/Xcode/iOS DeviceSupport")
        XCTAssertEqual( CleanMyXCode.GlobalSwiftPackagesCashes.url.path, "/Users/\(NSUserName())/Library/Caches/org.swift.swiftpm")
        XCTAssertEqual( CleanMyXCode.GlobalCoreSimulator.url.path,       "/Users/\(NSUserName())/Library/Developer/CoreSimulator/Devices")
        XCTAssertEqual( CleanMyXCode.GlobalArchives.url.path,            "/Users/\(NSUserName())/Library/Developer/Xcode/Archives")
    }
    
    func test_GetWeightAndIsReacheble() {
        CleanMyXCode.shared.isGlobalDirsReacheble.assertEqual(to: true)
        
        let a = CleanMyXCode.shared.getWeight(of: CleanMyXCode.GlobalDerivedData.url ).shouldSucceed()!
        XCTAssertTrue( a > 0 )
    }
    
    func test_XcodeIsRunned() {
        XCTAssertTrue(CleanMyXCode.shared.xcodeIsRunned)
    }
}
