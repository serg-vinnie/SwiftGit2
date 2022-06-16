import Essentials

public extension URL {
    @discardableResult
    func createSubDir(named: String) -> R<URL>  {
        URL.createDir(path: self.appendingPathComponent(named).path )
    }
    
    func exist() -> Bool {
        return URL.exist(at: self.path)
    }
    
    var fileSize: UInt64 {
        return attributes?[.size] as? UInt64 ?? UInt64(0)
        //possibly better to use "self.resourceBytes" ?
    }
    
    var attributes: [FileAttributeKey : Any]? {
        do {
            return try FileManager.default.attributesOfItem(atPath: path)
        } catch let error as NSError {
            print("FileAttribute error: \(error)")
        }
        return nil
    }
}

public extension URL {
    /// Synonim of createDir
    @discardableResult
    static func mkDir(path: String) -> R<URL> {
        URL.createDir(path: path)
    }
    
    @discardableResult
    static func createDir(path: String) -> R<URL> {
        if URL.exist(at: path) {
            return .wtf("Dir already exist: \(path)")
        }
        
        return Result {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        .flatMapError { err in
            return .wtf("Can't create dir at path : \(path). \nError: \(err.localizedDescription)")
        }
        .map { _ in
            return URL(fileURLWithPath: path, isDirectory: true)
        }
    }
    
    static func exist(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    static func fileSize(at filePath: String) -> UInt64 {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            return (attr[FileAttributeKey.size] as? UInt64 ) ?? 0
        } catch {
            print("Error: \(error)")
        }
        
        return 0
    }
    
    static func sizeOnDisk(_ size: Int) throws -> String? {
        try? sizeOnDisk(UInt64(size))
    }
    
    static func sizeOnDisk(_ size: UInt64) throws -> String? {
        URL.byteCountFormatter.countStyle = .file
        
        guard let byteCount = URL.byteCountFormatter.string(for: size) else { return nil}
        
        return byteCount + " on disk"
    }
    
    private static let byteCountFormatter = ByteCountFormatter()
}
