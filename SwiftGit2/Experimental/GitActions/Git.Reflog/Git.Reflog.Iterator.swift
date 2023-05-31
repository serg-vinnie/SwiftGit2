
import Foundation
import Essentials
import Clibgit2

public final class GitReflogIterator : RandomAccessCollection {
    let reflog : Reflog
    let repoID : RepoID
    
    public typealias Element = ReflogEntry
    public typealias Index = Int
    public typealias Indices = DefaultIndices<GitReflogIterator>
    
    init(reflog: Reflog, repoID: RepoID) {
        self.reflog = reflog
        self.repoID = repoID
    }
    
    public subscript(position: Int) -> ReflogEntry {
        _read {
            let element = reflog.entry(idx: position, repoID: repoID)!
            yield element
        }
    }
    
    public var startIndex   : Int { 0 }
    public var endIndex     : Int { reflog.entryCount }
    
    public func index(before i: Int)    -> Int { return i - 1 }
    public func index(after i: Int)     -> Int { return i + 1 }
}
