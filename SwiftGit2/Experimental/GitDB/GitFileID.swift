
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
    var flags : R<GitFileFlags> {
        let opt = StatusOptions(flags: [.includeUnmodified] , pathspec: [self.path])
        let status = blobID.repoID.status(options: opt)
        return status | { $0._flags(fileID: self) }
    }
}

extension StatusIterator {
    func _flags(fileID: GitFileID) -> R<GitFileFlags> {
        if count == 0 { return .success(GitFileFlags(fileID: fileID, fileExists: false, isAtHEAD: false, isAtHomeDir: false)) }
        guard count == 1 else { return .wtf("status.count != 1") }
        
        let entry = self[0]
        guard let file = entry.headToIndex?.newFile else { return .wtf("file doesn't exist in StatusEntry.headToIndex") }
        
        if entry.status == .current {
            if file.oid == fileID.blobID.oid {
                return .success(GitFileFlags(fileID: fileID, fileExists: true, isAtHEAD: true, isAtHomeDir: true))
            } else {
                return .success(GitFileFlags(fileID: fileID, fileExists: true, isAtHEAD: false, isAtHomeDir: true))
            }
        } else {
            if file.oid == fileID.blobID.oid {
                return .success(GitFileFlags(fileID: fileID, fileExists: true, isAtHEAD: true, isAtHomeDir: false))
            } else {
                return .success(GitFileFlags(fileID: fileID, fileExists: true, isAtHEAD: false, isAtHomeDir: false))
            }
        }
    }
}


public struct GitFileFlags : Equatable, Hashable {
    public let fileID: GitFileID
    public let fileExists: Bool
    public let isAtHEAD: Bool
    public let isAtHomeDir: Bool
}

public extension GitFileFlags {
    var canShowInFinder : Bool {
        fileExists && isAtHEAD
    }
}
