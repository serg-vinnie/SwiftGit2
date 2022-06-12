import Essentials

public extension URL {
    @discardableResult
    func createSubDir(named: String) -> R<URL>  {
        URL.createDir(path: self.appendingPathComponent(named).path )
    }
    
    func exist() -> Bool {
        return URL.exist(at: self.path)
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
}
