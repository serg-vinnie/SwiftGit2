
import Foundation
import Clibgit2
import Essentials

public struct GitBlame {
    
}

extension Optional where Wrapped == UnsafeMutablePointer<Any> {
    var asResult : R<Wrapped.Pointee> {
        if let val = self {
            return .success(val)
        }
        return .notImplemented
    }
    
    var asPointee : Wrapped.Pointee? {
        if let val = self {
            return val.pointee
        }
        return nil
    }
}

public struct BlameHunk {
    let fileID : GitFileID
    let hunk : git_blame_hunk
    
    var linesCount: Int     { Int(hunk.lines_in_hunk) }
    var startLine: Int      { Int(hunk.orig_start_line_number)}
    var oid: OID            { OID(hunk.orig_commit_id) }
    var commidID: CommitID  { CommitID(repoID: fileID.repoID, oid: self.oid) }
    var origPath: String    { hunk.orig_path.asSwiftString }
    var origSignature : GitSignature? {
        if let sig = hunk.orig_signature {
            return GitSignature(sig.pointee)
        }
        return nil
    }
    var finalSignature : GitSignature? {
        if let sig = hunk.final_signature {
            return GitSignature(sig.pointee)
        }
        return nil
    }
}

public extension GitFileID {
    func blame(options: BlameOptions = BlameOptions()) -> R<[BlameHunk]> {
        self.repoID.repo | { $0.blame(path: self.path) } | { $0.hunks(fileID: self) }
    }
}

extension Blame {
    func hunks(fileID: GitFileID) -> R<[BlameHunk]> {
        var list = [BlameHunk]()
        
        for i in 0...self.hunkCount {
            switch self.hunk(idx: i) {
            case .success(let hunk): 
                list.append(BlameHunk(fileID: fileID, hunk: hunk))
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(list)
    }
}
