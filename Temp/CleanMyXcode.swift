import Foundation
import Essentials
import SwiftUI

public class CleanMyXCode {
    static var libraryDir = URL.userHome.appendingPathComponent("Library")
    public static var xcodeBundle = "com.apple.dt.Xcode"
    
    public static func clean(urls: [URL]) {
        let _ = urls.map { FS.delete($0.path) }
    }
    
    public static func getWeight(of url: URL) -> Result<Int, Error> {
        url.directoryTotalAllocatedSizeR(includingSubfolders: true)
            .flatMapError { _ in return .success(0) }
            .map { $0 ?? 1 }
    }
    
    public static func getWeight(fromBites bites: Int) -> String {
        ByteCountFormatter()
            .string(fromByteCount: Int64(bites))
            .replace(of: "Zero", to: "0")
    }
    
    public static var isLibraryIsReacheble : Result<Bool, Error> {
        return CleanMyXCode.libraryDir.isDirectoryAndReachableR()
    }
    
    public static var xcodeIsRunned: Bool {
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

public extension CleanMyXCode {
    class LocalCashes {
        public private(set) var packageResolved: URL? = nil
        public private(set) var xcworkspaceXcuserdata: URL? = nil
        public private(set) var xcodeprojXcuserdata: [URL]?
        
        public init(repoPath: String?) {
            guard let repoPath = repoPath
            else {
                packageResolved = nil
                xcworkspaceXcuserdata = nil
                xcodeprojXcuserdata = []
                return
            }
            
            let workspace = XcodeHelper
                .getXcodeProjetPaths(repoPath: repoPath)
                .filter{ $0.hasSuffix(".xcworkspace")}
                .first
            
            if let packageUrl = workspace?.appending("/xcshareddata/swiftpm/Package.resolved").asURL() {
                self.packageResolved = packageUrl.exists ? packageUrl : nil
            }
            
            if let xcuserdataUrl = workspace?.appending("/xcuserdata").asURL(){
                self.xcworkspaceXcuserdata = xcuserdataUrl.exists ? xcuserdataUrl : nil
            }
            
            ////// ///
            self.xcodeprojXcuserdata = XcodeHelper
                .getXcodeProjetPaths(repoPath: repoPath)
                .filter{ !$0.hasSuffix(".xcworkspace") }
                .map{ $0.asURL().appendingPathComponent("/xcuserdata") }
                .filter{ $0.exists }
            
            //case ???? TaoGit.xcodeproj/xcshareddata/ - це МОЖЛИВО потрібно!!!!
            //https://stackoverflow.com/a/53039267/4423545
        }
    }
}

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

public class XcodeHelper {
    public static func getXcodeProjetPaths(repoPath: String) -> [String] {
        var urls = [String]()
        
        if let paths = try? FileManager.default.contentsOfDirectory(atPath: repoPath) {
            urls = paths.map{ path -> String? in
                if path.hasSuffix(".xcworkspace") || path.hasSuffix(".xcodeproj") {
                    return "\(repoPath)/\(path)"
                }
                
                return nil
            }
            .compactMap{ $0 }
        }
        
        if urls.count == 0 {
            urls = getXcodeProjetUrlsDeep(repoUrl: repoPath.asURL() )
        }
        
        return urls
    }

    // DO NOT USE ME IN ANOTHER PLACES EXCEPT getXcodeProjetPaths
    fileprivate static func getXcodeProjetUrlsDeep(repoUrl: URL) -> [String] {
        var urls = [URL]()
        if let dirContents = FileManager.default.enumerator(at: repoUrl, includingPropertiesForKeys: nil) {
            
            var fileCounter = 0
            
            while let url = dirContents.nextObject() as? URL {
                fileCounter += 1
                
                if fileCounter > 1000 {
                    break
                }
                
                if url.path.hasSuffix(".xcworkspace") || url.path.hasSuffix(".xcodeproj") {
                    urls.append(url)
                }
            }
        }
        
        return urls
            .sorted{ $0.pathComponents.count < $1.pathComponents.count }
            .map{ $0.path }
    }
}
