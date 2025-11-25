
import Clibgit2
import Foundation
import Essentials

public extension Diff {
    func asDeltasWithHunks(options: DiffOptions = DiffOptions()) -> R<[Delta]> {
        var cb = options.callbacks

        return _result({ cb.deltas }, pointOfFailure: "git_diff_foreach") {
            git_diff_foreach(self.pointer, cb.each_file_cb, nil, cb.each_hunk_cb, cb.each_line_cb, &cb)
        }
    }
    
    var numDeltas : Int { git_diff_num_deltas(self.pointer) }
    
    func asDeltas() -> [Delta] {
        var deltas = [Delta]()
        deltas.reserveCapacity(numDeltas)
        
        for i in 0..<numDeltas {
            if let d = delta(idx: i) {
                deltas.append(d)
            }
        }
        
        return deltas
    }
    
    func delta(idx: Int) -> Diff.Delta? {
        if let delta = git_diff_get_delta(self.pointer, idx).optional {
            return Diff.Delta(delta.pointee)
        }
        return nil
    }
}

nonisolated(unsafe) fileprivate let zero_OID = OID(string: "0000000000000000000000000000000000000000")!
public extension OID {
    static var zero : OID { zero_OID }
}

extension Diff.Delta {
    public func blobDiffID(repoID: RepoID) -> BlobDiffID {
        return BlobDiffID(oldBlob: oldBlobID(repoID: repoID), newBlob: newBlobID(repoID: repoID))
    }
    
    func oldBlobID(repoID: RepoID) -> BlobID? {
        guard let file = oldFile else { return nil }
        guard file.oid != OID.zero else { return nil }
        return BlobID(repoID: repoID, oid: file.oid, path: file.path)
    }
    
    func newBlobID(repoID: RepoID) -> BlobID? {
        guard let file = newFile else { return nil }
        return BlobID(repoID: repoID, oid: file.oid, path: file.path)
    }
}

public extension Diff {
    struct Delta {
        public static let type = GIT_OBJECT_REF_DELTA

        public let status: Diff.Delta.Status
        public let statusChar: Character
        public let flags: Flags
        public let oldFile: File?
        public let newFile: File?

        /// DELETE ME.
        /// SOMETIMES THIS HUNKS IS EMPTY
        /// USE repo.hunksFrom(delta....)
        internal var hunks = [Hunk]()

        public init(_ delta: git_diff_delta) {
            status = Diff.Delta.Status(rawValue: delta.status.rawValue) ?? .unmodified
            statusChar = Character(UnicodeScalar(UInt8(git_diff_status_char(delta.status))))
            flags = Flags(rawValue: delta.flags)
            oldFile = File(delta.old_file)
            newFile = File(delta.new_file)
        }
    }
}

extension Diff.Delta: Identifiable {
    public var id: String {
        var finalId: String = ""

        if let newPath = newFile?.path { finalId += newPath }

        if let oldPath = oldFile?.path { finalId += oldPath }

        return finalId
    }
}

extension Diff.Delta.Status : CustomStringConvertible {
    public var description: String {
        switch self {
        case .unmodified:   ".unmodified"
        case .added:        ".added"
        case .deleted:      ".deleted"
        case .modified:     ".modified"
        case .renamed:      ".renamed"
        case .copied:       ".copied"
        case .ignored:      ".ignored"
        case .untracked:    ".untracked"
        case .typechange:   ".typechange"
        case .unreadable:   ".unreadable"
        case .conflicted:   ".conflicted"
        }
    }
}

extension Diff.Delta.StatusEx : CustomStringConvertible {
    public var description: String {
        switch self {
        case .unmodified:       ".unmodified"
        case .added:            ".added"
        case .deleted:          ".deleted"
        case .modified:         ".modified"
        case .renamed:          ".renamed"
        case .renamedAdded:     ".renamedAdded"
        case .renamedDeleted:   ".renamedDeleted"
        case .copied:           ".copied"
        case .ignored:          ".ignored"
        case .untracked:        ".untracked"
        case .typechange:       ".typechange"
        case .unreadable:       ".unreadable"
        case .conflicted:       ".conflicted"
        }
    }
}

public extension Diff.Delta.Status {
    var asEx : Diff.Delta.StatusEx {
        return Diff.Delta.StatusEx(rawValue: Int(self.rawValue))!
    }
}

public extension Diff.Delta {
    enum Status: UInt32 {
        case unmodified = 0 /** < no changes */
        case added = 1 /** < entry does not exist in old version */
        case deleted = 2 /** < entry does not exist in new version */
        case modified = 3 /** < entry content changed between old and new */
        case renamed = 4 /** < entry was renamed between old and new */
        case copied = 5 /** < entry was copied from another old entry */
        case ignored = 6 /** < entry is ignored item in workdir */
        case untracked = 7 /** < entry is untracked item in workdir */
        case typechange = 8 /** < type of entry changed between old and new */
        case unreadable = 9 /** < entry is unreadable */
        case conflicted = 10 /** < entry in the index is conflicted */
    } // git_delta_t
    
    enum StatusEx: Int {
        case unmodified = 0
        case added = 1
        case deleted = 2
        case modified = 3
        case renamed = 4
        case renamedAdded   = 44
        case renamedDeleted = -44
        case copied = 5
        case ignored = 6
        case untracked = 7
        case typechange = 8
        case unreadable = 9
        case conflicted = 10
    }
}

public extension Diff {
    struct File {
        public let oid: OID
        public let path: String
        public let size: UInt64
        public let flags: Flags
        
        /// is null by default
//        public var blob: Blob?

        public init(_ diffFile: git_diff_file) {
            oid = OID(diffFile.id)
            let path = diffFile.path
            self.path = path.map(String.init(cString:))!
            size = diffFile.size
            flags = Flags(rawValue: diffFile.flags)
        }
        
//        public var isBinary: Bool? { blob?.isBinary }
        
        /// return new instance of file with initialized blob
//        func getSameFileWithBlob(from repo: Repository) -> File {
//            var file: File? = self
//            
//            repo.loadBlobFor(file: &file)
//            
//            return file!
//        }
    }

    
    
}

