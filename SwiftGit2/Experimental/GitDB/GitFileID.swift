
import Foundation
import Essentials
import Parsing

public struct GitFileID : Hashable {
    public let path: String
    public let blobID: BlobID
    public let commitID: CommitID?
    
    public var repoID : RepoID { blobID.repoID }
    public var fullPath : String { repoID.path + "/" + path }
    public var url : URL { URL(fileURLWithPath: fullPath) }
    public var displayName : String { url.lastPathComponent }
    
    public init(path: String, blobID: BlobID, commitID: CommitID?) {
        self.path = path
        self.blobID = blobID
        self.commitID = commitID
    }
}

public extension GitFileID {
    struct SubLines {
        let content : String
        let lines: [String.SubSequence]
        let isBinary: Bool
    }
    
    var subLines : R<SubLines> {
        blobID.content | { $0.asSubLines }
    }
}

public extension GitFileID {
    var workDirBlobID : R<BlobID> {
        repoID.repo | { $0.blobCreateFromWorkdir(path: self.path) | { BlobID(repoID: self.repoID, oid: OID($0.oid), path: self.blobID.path) } }
    }
    
    var isInWorkDir : R<Bool> {
        workDirBlobID | { self.blobID == $0 }
    }
    
    func revert(intoFolder: URL? = nil) -> R<Void> {
        if let folder = intoFolder, !folder.isDirectory { return .wtf("intoFolder is not directory") }
        
        if let folder = intoFolder {
            let finalURL = folder.appendingPathComponent(self.url.lastPathComponent)
            return blobID.content | { $0.saveTo(url: finalURL) }
        }
        
        if url.exists {
            return blobID.content | { $0.saveTo(url: url) }
        } else {
            return .wtf("path no longer exist")
        }
    }
}

public extension GitFileID {
    var flags : R<GitFileFlags> {
        let opt = StatusOptions(flags: [.includeUnmodified] , pathspec: [self.path])
        let status = blobID.repoID.status(options: opt)
        return status | { $0._flags(fileID: self) }
    }
}

extension StatusIterator {
    func _flags(fileID: GitFileID) -> R<GitFileFlags> {
        if count == 0 { return .success(GitFileFlags(fileID: fileID, isWorkDirModified: false, fileExists: false, isAtHEAD: false, isAtWorkDir: false)) }
        guard count == 1 else { return .wtf("status.count != 1") }
        
        let entry = self[0]
        let isFileExists = fileID.url.exists
        
        
        if entry.status == .current {
            guard let file = entry.headToIndex?.newFile else { return .wtf("file doesn't exist in StatusEntry.headToIndex") }
            
            if file.oid == fileID.blobID.oid {
                return .success(GitFileFlags(fileID: fileID, isWorkDirModified: false, fileExists: isFileExists, isAtHEAD: true, isAtWorkDir: true))
            } else {
                return .success(GitFileFlags(fileID: fileID, isWorkDirModified: false, fileExists: isFileExists, isAtHEAD: false, isAtWorkDir: false))
            }
        } else {
            
//            print(fileID.path)
//            print(fileID.blobID.oid)
//            print(fileID.workDirBlobID.maybeSuccess?.oid)
//            print(entry.headToIndex?.newFile?.oid)
//            print(entry.headToIndex?.oldFile?.oid)
//            print(entry.indexToWorkDir?.newFile?.oid)
//            print(entry.indexToWorkDir?.oldFile?.oid)
            
            switch fileID.isInWorkDir {
            case .success(let isInWorkDir):
                if isInWorkDir {
                    return .success(GitFileFlags(fileID: fileID, isWorkDirModified: true, fileExists: isFileExists, isAtHEAD: false, isAtWorkDir: true))
                } else if entry.indexToWorkDir?.oldFile?.oid == fileID.blobID.oid {
                    return .success(GitFileFlags(fileID: fileID, isWorkDirModified: true, fileExists: isFileExists, isAtHEAD: true, isAtWorkDir: false))
                } else {
                    return .success(GitFileFlags(fileID: fileID, isWorkDirModified: true, fileExists: isFileExists, isAtHEAD: false, isAtWorkDir: false))
                }
            case .failure(let error): return .failure(error)
            }
        }
    }
}

extension GitFileFlags : CustomStringConvertible {
    public var description: String {
        "fileExists: \(fileExists), isAtHEAD: \(isAtHEAD), isAtHomeDir: \(isAtWorkDir)"
    }
    
    
}

public struct GitFileFlags : Equatable, Hashable {
    public let fileID: GitFileID
    public let isWorkDirModified: Bool
    public let fileExists: Bool
    public let isAtHEAD: Bool
    public let isAtWorkDir: Bool
}

