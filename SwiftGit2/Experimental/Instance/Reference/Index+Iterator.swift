//
//  Index+Iterator.swift
//  SwiftGit2-OSX
//
//  Created by loki on 03.06.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

extension Result {
    var maybeSuccess: Success? {
        switch self {
        case let .success(s):
            return s
        default:
            return nil
        }
    }
    
    var maybeFailure: Failure? {
        switch self {
        case let .failure(error):
            return error
        default:
            return nil
        }
    }
}

protocol ResultIterator {
    associatedtype Success
    
    func next() -> Result<Success, Error> 
}

internal extension Index {
    final class ConflictIterator: InstanceProtocol {
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
        
        func all() -> Result<[Conflict],Error> {
            var c = [Conflict]()
            
            var result = next()
            
            while c.insert(next: result) { //producer.update(element: element, completion: result.completion) {
              result = next()
            }
            
            if let error = result.maybeFailure {
                return .failure(error)
            }
            
            return .success(c)
        }
    }
}

extension Array where Element == SwiftGit2.Index.Conflict {
    mutating func insert(next: Result<Element?, Error>) -> Bool {
        switch next {
        case let .success(item):
            if let item = item {
                self.append(item)
                return true
            }
            return false
        default:
            return false
        }
    }
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


// Pointer example
//
// var our = UnsafeMutablePointer<UnsafePointer<git_index_entry>?>.allocate(capacity: 1)
// var their : UnsafePointer<git_index_entry>?
// git_index_conflict_next(our, &their, our, self.pointer)


// 4 essentials
