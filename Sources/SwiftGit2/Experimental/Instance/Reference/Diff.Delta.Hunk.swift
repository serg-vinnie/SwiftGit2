
import Clibgit2
import Foundation
import Essentials

public extension Diff {
    
    struct Hunk : Equatable, Hashable {
        public let oldStart: Int
        public let oldLines: Int
        public let newStart: Int
        public let newLines: Int
        public let header: String?
        
        public var lines: [Line]
        
        public init(_ hunk: git_diff_hunk, lines: [Line] = [Line]()) {
            oldStart = Int(hunk.old_start)
            oldLines = Int(hunk.old_lines)
            newStart = Int(hunk.new_start)
            newLines = Int(hunk.new_lines)
            
            let bytes = Mirror(reflecting: hunk.header)
                .children
                .map { UInt8(bitPattern: $0.value as! Int8) }
                .filter { $0 > 0 }
            
            header = String(bytes: bytes, encoding: .utf8)
            self.lines = lines
        }
    }
}

extension Diff.Hunk: Identifiable {
    public var id: Int {
        self.hashValue
    }
}

extension Diff.Hunk {
    public static func == (lhs: Diff.Hunk, rhs: Diff.Hunk) -> Bool {
        return lhs.oldLines == rhs.oldLines &&
            lhs.oldStart == rhs.oldStart &&
            lhs.newStart == rhs.newStart &&
            lhs.newLines == rhs.newLines &&
            lhs.header == rhs.header &&
            lhs.lines == rhs.lines
    }
}

 
public extension Diff {
    struct Line : Equatable, Hashable {
        public let origin: Int8
        public let old_lineno: Int
        public let new_lineno: Int
        public let num_lines: Int
        public let contentOffset: Int64
        public let content: String?

        public init(_ line: git_diff_line) {
            origin = line.origin
            old_lineno = Int(line.old_lineno)
            new_lineno = Int(line.new_lineno)
            num_lines = Int(line.num_lines)
            contentOffset = line.content_offset

            var bytes = [UInt8]()
            bytes.reserveCapacity(line.content_len)
            for i in 0 ..< line.content_len {
                bytes.append(UInt8(bitPattern: line.content[i]))
            }

            content = String(bytes: bytes, encoding: .utf8)
        }
    }
}


