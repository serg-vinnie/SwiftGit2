
import Foundation
import Essentials
import Clibgit2

public final class GitReflogIterator : RandomAccessCollection {
    let reflog : Reflog
    
    public typealias Element = ReflogEntry
    public typealias Index = Int
    public typealias Indices = DefaultIndices<GitReflogIterator>
    
    init(reflog: Reflog) {
        self.reflog = reflog
    }
    
    public subscript(position: Int) -> ReflogEntry {
        _read {
            let element = reflog.entry(idx: position)!
            yield element
        }
    }
    
    public var startIndex   : Int { 0 }
    public var endIndex     : Int { reflog.entryCount }
    
    public func index(before i: Int)    -> Int { return i - 1 }
    public func index(after i: Int)     -> Int { return i + 1 }
}
