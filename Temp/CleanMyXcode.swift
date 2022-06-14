import Foundation
import Essentials
import SwiftUI

public class CleanMyXCode {
    public static var shared = CleanMyXCode()
    static var libraryDir = URL.userHome.appendingPathComponent("Library")
    public static var xcodeBundle = "com.apple.dt.Xcode"
    
    
    
    
    public func clean(urls: [URL]) {
        let _ = urls.map { FS.delete($0.path) }
    }
    
    public func getWeight(of url: URL) -> Result<Int, Error> {
        url.directoryTotalAllocatedSizeR(includingSubfolders: true)
            .flatMapError { _ in return .success(0) }
            .map { $0 ?? 1 }
    }
    
    public func getWeight(fromBites bites: Int) -> String {
        ByteCountFormatter()
            .string(fromByteCount: Int64(bites))
            .replace(of: "Zero", to: "0")
    }
//    
//    public func getWeight2(of type: CleanXcodeGlobal) -> Result<String?, Error> {
//        type.asUrl.sizeOnDiskR()
//    }
//    
    public var isGlobalDirsReacheble : Result<Bool, Error> {
        return CleanMyXCode.libraryDir.isDirectoryAndReachableR()
    }
    
    public var xcodeIsRunned: Bool {
        let runnedAppsBundles = NSWorkspace.shared.runningApplications.map{ $0.bundleIdentifier }.compactMap{ $0 }
        
        return runnedAppsBundles.contains(CleanMyXCode.xcodeBundle)
    }
}

public protocol CashDir {
    static var url: URL { get }
    static var title: String { get }
}

public extension CleanMyXCode {
    class GlobalDerivedData : CashDir {
        public static let url = CleanMyXCode.libraryDir.appendingPathComponent("Developer/Xcode/DerivedData")
        public static let title = "Derived Data (global)"
        public static var exist: Bool { url.exists }
        
        public static func cleanup() {
            FS.delete(url.path)
        }
    }
}

public extension CleanMyXCode {
    class GlobalArchives : CashDir {
        public static let url = CleanMyXCode.libraryDir.appendingPathComponent("Developer/Xcode/Archives")
        public static let title = "Archives"
        public static var exist: Bool { url.exists }
        
        public static func cleanup() {
            FS.delete(url.path)
        }
    }
}

public extension CleanMyXCode {
    class GlobalDeviceSupport : CashDir {
        public static let url = CleanMyXCode.libraryDir.appendingPathComponent("Developer/Xcode/iOS DeviceSupport")
        public static let title = "iOS DeviceSupport"
        public static var exist: Bool { url.exists }
        
        public static func cleanup() {
            FS.delete(url.path)
        }
    }
}

public extension CleanMyXCode {
    class GlobalCoreSimulator : CashDir {
        public static let url = CleanMyXCode.libraryDir.appendingPathComponent("Developer/CoreSimulator/Devices")
        public static let title = "CoreSimulator"
        public static var exist: Bool { url.exists }
        
        public static func cleanup() {
            FS.delete(url.path)
        }
    }
}

public extension CleanMyXCode {
    class GlobalSwiftPackagesCashes : CashDir {
        public static let url = CleanMyXCode.libraryDir.appendingPathComponent("Caches/org.swift.swiftpm")
        public static let title = "Swift packages Cashes"
        public static var exist: Bool { url.exists }
        
        public static func cleanup() {
            FS.delete(url.path)
        }
    }
}




//public enum CleanXcodeGlobal: CaseIterable {
//    case derivedData
//    case archives
//    case simulatorData
//    case deviceSupport
//    case swiftPmCashes
//}
//
//public extension CleanXcodeGlobal {
//    var asUrl: URL {
//        let libFldr = CleanMyXCode.libraryDir
//
//        switch self {
//        case .derivedData:
//            return libFldr.appendingPathComponent("Developer/Xcode/DerivedData")
//        case .archives:
//            return libFldr.appendingPathComponent("Developer/Xcode/Archives")
//        case .deviceSupport:
//            return libFldr.appendingPathComponent("Developer/Xcode/iOS DeviceSupport")
//        case .simulatorData:
//            return libFldr.appendingPathComponent("Developer/CoreSimulator/Devices")
//        case .swiftPmCashes:
//            return libFldr.appendingPathComponent("Caches/org.swift.swiftpm/")
//        }
//    }
//
//    var asTitle: String {
//        switch self {
//        case .derivedData:
//            return "Derived Data (global)"
//        case .archives:
//            return "Archives"
//        case .deviceSupport:
//            return "iOS DeviceSupport"
//        case .simulatorData:
//            return "CoreSimulator"
//        case .swiftPmCashes:
//            return "Swift packages Cashes"
//        }
//    }
//}

fileprivate extension URL {
    func isDirectoryAndReachableR() -> Result<Bool, Error> {
        return Result {
            try resourceValues(forKeys: [.isDirectoryKey]).isDirectory
        }
        .flatMap { isDir in
            guard let isDir = isDir
            else { return .success(false) }
            
            if !isDir { return .success(false) }
            
            return Result { try checkResourceIsReachable() }
        }
    }
    
    func directoryTotalAllocatedSizeR(includingSubfolders: Bool = true) -> Result<Int?, Error> {
        Result{ try directoryTotalAllocatedSize(includingSubfolders: includingSubfolders) }
    }
    
    func sizeOnDiskR() -> Result<String?, Error> {
        Result{ try sizeOnDisk() }
    }
    
    private func directoryTotalAllocatedSize(includingSubfolders: Bool) throws -> Int? {
        guard try isDirectoryAndReachableR().get() else { return nil }
        if includingSubfolders {
            guard
                let urls = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL] else { return nil }
            return try urls.lazy.reduce(0) {
                    (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0) + $0
            }
        }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil).lazy.reduce(0) {
                 (try $1.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
                    .totalFileAllocatedSize ?? 0) + $0
        }
    }
    
    private func sizeOnDisk() throws -> String? {
        guard let size = try directoryTotalAllocatedSize(includingSubfolders: true) else { return nil }
        URL.byteCountFormatter.countStyle = .file
        guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil}
        return byteCount + " on disk"
    }
    private static let byteCountFormatter = ByteCountFormatter()
}



fileprivate func getPlistValue(url: URL, key: String) -> String? {
    if let xml = FileManager.default.contents(atPath: url.path) {
        return (try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil)) as? String
    }
    
    return nil
}
