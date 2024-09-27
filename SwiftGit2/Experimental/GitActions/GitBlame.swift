
import Foundation
import Clibgit2
import Essentials
import Parsing

public struct GitBlame {
    let _blame : Blame
    public let fileID : GitFileID
    public let subLines : GitFileID.SubLines
    public let hunks: [BlameHunk]
    
    public static func create(fileID: GitFileID, options: BlameOptions = BlameOptions()) -> R<GitBlame> {
        let subLines = fileID.subLines
        let blame = fileID.repoID.repo | { $0.blame(path: fileID.path, options: options) }
        let hunks = blame | { $0.hunks(fileID: fileID) }
        
        return combine(blame, subLines, hunks) | { blame, subLines, hunks in
            GitBlame(_blame: blame, fileID: fileID, subLines: subLines, hunks: hunks)
        }
    }
}

extension String {
    var subStrings : R<[String.SubSequence]> {        
        return .success(self.split(separator: "\n", omittingEmptySubsequences: false))
    }
}

public extension GitFileID {
    func blame(options: BlameOptions = BlameOptions()) -> R<GitBlame> {
        GitBlame.create(fileID: self, options: options)
    }
}

extension GitFileID.SubLines {
    func at(idx: Int, len: Int) -> R<[GitBlame.Line]> {
        guard idx+len <= self.lines.count else { return .wtf("idx out of bounds: \(idx)+\(len) <= \(lines.count)") }
        
        var lines = [GitBlame.Line]()
        
        for i in idx..<idx+len {
            lines.append(GitBlame.Line(num: i, substring: self.lines[i]))
        }
        
        return .success(lines)
    }
}

public extension GitBlame {
    struct Line {
        public let num : Int
        public let substring : String.SubSequence
    }
    
    func lines(in hunk: BlameHunk) -> R<[GitBlame.Line]> {
        //let origLines = self.subLines.at(idx: hunk.origStartLine, len: hunk.linesCount)
        return self.subLines.at(idx: hunk.finalStartLine, len: hunk.linesCount)
    }
}

public struct BlameHunk {
    public let fileID : GitFileID
    public let hunk : git_blame_hunk
    public let idx: Int
    
    public var linesCount: Int         { Int(hunk.lines_in_hunk) }
    public var origStartLine: Int      { Int(hunk.orig_start_line_number) }
    public var finalStartLine: Int     { Int(hunk.final_start_line_number) }
    public var origOID : OID            { OID(hunk.orig_commit_id) }
    public var finalOID: OID            { OID(hunk.final_commit_id) }
    public var origCommidID: CommitID   { CommitID(repoID: fileID.repoID, oid: origOID) }
    public var finalCommidID: CommitID  { CommitID(repoID: fileID.repoID, oid: finalOID) }
    public var origPath: String    { hunk.orig_path.asSwiftString }
    
    public var origFileID: R<GitFileID> {
//        let blobID = origCommidID.
        
        return .notImplemented
    }
    public var origSignature : GitSignature? {
        if let sig = hunk.orig_signature {
            return GitSignature(sig.pointee)
        }
        return nil
    }
    public var finalSignature : GitSignature? {
        if let sig = hunk.final_signature {
            return GitSignature(sig.pointee)
        }
        return nil
    }
}



extension Blame {
    func hunks(fileID: GitFileID) -> R<[BlameHunk]> {
        var list = [BlameHunk]()
        
        for i in 0..<self.hunkCount {
            switch self.hunk(idx: i) {
            case .success(let hunk): 
                list.append(BlameHunk(fileID: fileID, hunk: hunk, idx: Int(i)))
            case .failure(let error):
                return .failure(error)
            }
        }
        
        return .success(list)
    }
}

