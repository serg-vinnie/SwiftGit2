import Foundation
import Essentials
import SwiftUI

public class CleanMyXCode {
    public static var shared = CleanMyXCode()
    static var libraryDir = FileManager.default.homeDirectory(forUser: NSUserName() )!.appendingPathComponent("Library")
    
    public func clean(config: [CleanXcodeGlobal]) -> R<()> {
        //Correct code
//        config.map { $0.asUrl }
//            .map { FS.delete($0.path) }
//            .flatMap { $0 }
//            .map { _ in () }
        
        //INCORRECT code
        config.map { $0.asUrl }
            .map { FS.delete($0.path) }
        
        return .success(())
    }
    
    public func getWeight(of type: CleanXcodeGlobal) -> Result<Int, Error> {
        type.asUrl.directoryTotalAllocatedSizeR(includingSubfolders: true)
            .flatMapError { _ in return .success(0) }
            .map { $0! }
    }
    
    public func getWeightForHuman(of type: CleanXcodeGlobal) -> Result<String, Error> {
        getWeight(of: type)
            .map { bites in
                let bcf = ByteCountFormatter()
                
                return bcf.string(fromByteCount: Int64(bites))
            }
    }
    
    public func getWeight2(of type: CleanXcodeGlobal) -> Result<String?, Error> {
        type.asUrl.sizeOnDiskR()
    }
    
    public var isGlobalDirsReacheble : Result<Bool, Error> {
        return CleanMyXCode.libraryDir.isDirectoryAndReachableR()
    }
    
    public var xcodeIsRunned: Bool {
        let runnedAppsBundles = NSWorkspace.shared.runningApplications.map{ $0.bundleIdentifier }.compactMap{ $0 }
        
        return runnedAppsBundles.contains("com.apple.dt.Xcode")
    }
}

public enum CleanXcodeGlobal: CaseIterable {
    case derivedData
    case archives
    case simulatorData
    case deviceSupport
}

public enum CleanXcodeLocal: CaseIterable {
    case packagesResolved //URL(string:".xcworkspace/xcshareddata/swiftpm")
    case xcworkspaceXcuserdata // .xcworkspace/xcuserdata/
    case xcodeprojXcuserdata // .xcodeproj/xcuserdata/
    
    //case ???? TaoGit.xcodeproj/xcshareddata/ - це МОЖЛИВО потрібно!!!! Але точно не в гітігнор https://stackoverflow.com/a/53039267/4423545
}

public extension CleanXcodeGlobal {
    var asUrl: URL {
        let libFldr = CleanMyXCode.libraryDir
    
        switch self {
        case .derivedData:
            return libFldr.appendingPathComponent("Developer/Xcode/DerivedData")
        case .archives:
            return libFldr.appendingPathComponent("Developer/Xcode/Archives")
        case .deviceSupport:
            return libFldr.appendingPathComponent("Developer/Xcode/iOS DeviceSupport")
        case .simulatorData:
            return libFldr.appendingPathComponent("Developer/CoreSimulator/Devices")
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
