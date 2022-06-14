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
        CleanMyXCode.isLibraryIsReacheble.assertEqual(to: true)
        
        let a = CleanMyXCode.getWeight(of: CleanMyXCode.GlobalDerivedData.url ).shouldSucceed()!
        XCTAssertTrue( a > 0 )
        
        CleanMyXCode.GlobalDeviceSupport.url.mkdir().shouldSucceed()!
        try? File(url: CleanMyXCode.GlobalDeviceSupport.url.appendingPathComponent("File.txt")).setContent(String(repeating: "String____Help_me_they_can kill_me!", count: 50000))
        
        let b = CleanMyXCode.getWeight(of: CleanMyXCode.GlobalDeviceSupport.url ).shouldSucceed()!
        XCTAssertTrue( b > 0 )
        
        CleanMyXCode.clean(urls: [CleanMyXCode.GlobalDeviceSupport.url])
        
        let c = CleanMyXCode.getWeight(of: CleanMyXCode.GlobalDeviceSupport.url ).shouldSucceed()!
        XCTAssertTrue( c == 0 )
    }
    
    func test_XcodeIsRunned() {
        XCTAssertTrue(CleanMyXCode.xcodeIsRunned)
    }
}
