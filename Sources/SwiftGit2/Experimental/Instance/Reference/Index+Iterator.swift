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
        
        func next() -> Result<String?,Error> {
            var _their      : UnsafePointer<git_index_entry>?
            var _our        : UnsafePointer<git_index_entry>?
            var _ancestor   : UnsafePointer<git_index_entry>?
            
            let result = git_index_conflict_next(&_ancestor, &_our, &_their, self.pointer)
            if result == GIT_OK.rawValue {
                return .success( pathFromConflict(their: _their, our: _our, ancestor: _ancestor) )
            } else if result == GIT_ITEROVER.rawValue {
                return .success(nil)
            }
            
            return .failure(NSError(gitError: result, pointOfFailure: "git_index_conflict_next"))
        }
    }
    
    // ResultIterator.all() -> Result<[Success], Error>
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

//
// Helpers
//

fileprivate func pathFromConflict(their: UnsafePointer<git_index_entry>?, our: UnsafePointer<git_index_entry>?, ancestor: UnsafePointer<git_index_entry>?) -> String? {
    return our.asNonOptional.map{ $0.pointee.path }.flatMap{ $0.asNonOptional }.map{ String(cString: $0) }.maybeSuccess ??
        their.asNonOptional.map{ $0.pointee.path }.flatMap{ $0.asNonOptional }.map{ String(cString: $0) }.maybeSuccess ??
        ancestor.asNonOptional.map{ $0.pointee.path }.flatMap{ $0.asNonOptional }.map{ String(cString: $0) }.maybeSuccess
}
