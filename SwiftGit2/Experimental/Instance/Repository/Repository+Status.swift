import Clibgit2
import Essentials

public final class StatusIterator {
    public var pointer: OpaquePointer?
    
    public init(_ pointer: OpaquePointer?) {
        self.pointer = pointer
    }
    
    deinit {
        if let pointer = pointer {
            git_status_list_free(pointer)
        }
    }
}

extension StatusIterator: RandomAccessCollection {
    public typealias Element = StatusEntry
    public typealias Index = Int
    //public typealias SubSequence = StatusIterator
    public typealias Indices = DefaultIndices<StatusIterator>
    
    public subscript(position: Int) -> StatusEntry {
        _read {
            let s = git_status_byindex(pointer!, position)
            yield StatusEntry(from: s!.pointee)
        }
    }
    
    public var startIndex: Int { 0 }
    public var endIndex: Int {
        if let pointer = pointer {
            return git_status_list_entrycount(pointer)
        }
        
        return 0
    }
    
    public func index(before i: Int) -> Int { return i - 1 }
    public func index(after i: Int) -> Int { return i + 1 }
}


public extension ExtendedStatus.HEAD {
    var headCommmit : R<CommitID> {
        switch self {
        case .isUnborn: return .wtf("head is unborn")
        case .reference(let ref): return ref.targetOID | { CommitID(repoID: ref.repoID, oid: $0) }
        case .dettached(let com): return .success(com)
        }
    }
}

extension Repository {
    func extendedStatus(options: StatusOptions = StatusOptions()) -> R<ExtendedStatus> {
        if headIsUnborn {
            return statusConflictSafe(options: options) | { ExtendedStatus(status: $0, isConflicted: false, head: .isUnborn) }
        }
        
        let repoID = self.repoID
        let isConflicted = repoID | { GitConflicts(repoID: $0).exist() }
        
        if headIsDetached {
            let headOID = HEAD().flatMap{ Duo($0, self).targetOID() }
            
            return combine(statusConflictSafe(options: options), isConflicted, repoID, headOID)
            | { ExtendedStatus(status: $0, isConflicted: $1, head: .dettached(CommitID(repoID: $2, oid: $3))) }
        }
        
        let ref = self.repoID | { $0.HEAD } | { $0.asReference }
        return combine(statusConflictSafe(options: options), isConflicted,ref)
        | { ExtendedStatus(status: $0, isConflicted: $1, head: .reference($2)) }
    }
}


public extension RepoID {
    func status(options: StatusOptions = StatusOptions()) -> R<StatusIterator> {
        self.repo | { $0.statusConflictSafe(options: options) }
    }
    
    func statusEx(options: StatusOptions = StatusOptions()) -> R<ExtendedStatus> {
        self.repo | { $0.extendedStatus(options: options) }
    }
}

public extension Repository {
    // CheckThatRepoIsEmpty
    var repoIsBare: Bool {
        git_repository_is_bare(pointer) == 1 ? true : false
    }
    
    
    internal func statusConflictSafe(options: StatusOptions = StatusOptions()) -> R<StatusIterator> {
        var newFlags = options.flags
        newFlags.remove(.includeUntracked)
        let conflictOptions = StatusOptions(flags: newFlags, show: options.show, pathspec: options.pathspec)
        
        return index()
            .flatMap {
                $0.hasConflicts
                ? status(options: conflictOptions)
                : status(options: options)
            }
    }
    
    internal func status(options: StatusOptions = StatusOptions()) -> R<StatusIterator> {
        var pointer: OpaquePointer?
        
        if repoIsBare {
            return .success( StatusIterator(nil) )
        }
        
        return options.with_git_status_options { options in
            _result({ StatusIterator(pointer!) }, pointOfFailure: "git_status_list_new") {
                git_status_list_new(&pointer, self.pointer, &options)
            }
        }
        //.map{ StatusIteratorNew(iterator: $0, repo: self )}
    }
}

//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
//////////////////////////////////////////
/////////////////////////////////////////

public final class StatusIteratorNew {
    public var repo: Repository
    public var iterator: StatusIterator
    
    public init( iterator: StatusIterator, repo: Repository ) {
        self.iterator = iterator
        self.repo = repo
    }
}

public extension StatusEntry {
    var oldFileRelPath: String? { self.headToIndex?.oldFile?.path ?? self.indexToWorkDir?.oldFile?.path }
    
    var newFileRelPath: String? { self.headToIndex?.newFile?.path ?? self.indexToWorkDir?.newFile?.path }
    
    /// headToIndex old + new | indexToWorkDir old + new
    var allPaths: [String?] {
        [self.headToIndex?.oldFile?.path,
         self.indexToWorkDir?.oldFile?.path,
         self.headToIndex?.newFile?.path,
         self.indexToWorkDir?.newFile?.path
        ]
    }
}

public extension StatusEntry {
    var unStagedDeltas: Diff.Delta? { self.indexToWorkDir }
    
    var stagedDeltas: Diff.Delta? { self.headToIndex }
}
