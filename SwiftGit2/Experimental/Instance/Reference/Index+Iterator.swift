import Foundation
import Clibgit2
import Essentials

// Pointer example
//
// var our = UnsafeMutablePointer<UnsafePointer<git_index_entry>?>.allocate(capacity: 1)
// var their : UnsafePointer<git_index_entry>?
// git_index_conflict_next(our, &their, our, self.pointer)


internal extension Index {
    final class ConflictIterator: InstanceProtocol, ResultIterator {
        public var pointer: OpaquePointer
        
        public required init(_ pointer: OpaquePointer) {
            self.pointer = pointer
        }
        
        deinit {
            git_index_conflict_iterator_free(pointer)
        }
        
        func next() -> Result<Conflict?,Error> {
            let c = Conflict()
            let result = git_index_conflict_next(&c._ancestor, &c._our, &c._their, self.pointer)
            if result == GIT_OK.rawValue {
                return .success(c)
            } else if result == GIT_ITEROVER.rawValue {
                return .success(nil)
            }
            return .failure(NSError(gitError: result, pointOfFailure: "git_index_conflict_next"))
        }
    }
    
    // ResultIterator.all() -> Result<[Success], Error>
}

public extension Index {
    class Conflict {
        fileprivate var _their      : UnsafePointer<git_index_entry>?
        fileprivate var _our        : UnsafePointer<git_index_entry>?
        fileprivate var _ancestor   : UnsafePointer<git_index_entry>?
        
        var our     : git_index_entry { return _our!.pointee }
        var their   : git_index_entry { return _their!.pointee }
        var ancestor: git_index_entry { return _ancestor!.pointee }
    }
}

extension Index : CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String {
        debugDescription
    }
    
    public var debugDescription: String {
        if let conflicts = try? conflicts().get() {
            return "\(conflicts)"
        }
        return "WTF"
    }
}

extension Index.Conflict : CustomDebugStringConvertible, CustomStringConvertible {
    public var description: String {
        debugDescription
    }
    
    public var debugDescription: String {
        if let path = _their?.pointee.path {
            return String(cString: path)
        }
        return "WTF"
    }
    
    
}
