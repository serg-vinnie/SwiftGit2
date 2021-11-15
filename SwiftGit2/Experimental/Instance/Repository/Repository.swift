//
//  RepositoryInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Repository: InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_repository_free(pointer)
    }
}

extension Repository {
    public func remote(of target: BranchTarget) -> R<Remote> { target.with(self).remote }
    
    public var directoryPath: Result<String, Error> {
        if let pathPointer = git_repository_workdir(pointer) {
            return .success( String(cString: pathPointer) )
        }
        
        return .failure(RepositoryError.FailedToGetRepoUrl as Error)
    }
    
    public var directoryURL: Result<URL, Error> { directoryPath | { $0.asURL() } }
    
    public var gitDirUrl: Result<URL, Error> {
        if let pathPointer = git_repository_commondir(pointer) {
            return .success( String(cString: pathPointer).asURL() )
        }
        return .failure(RepositoryError.FailedToGetRepoUrl as Error)
    }
}

extension Repository: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch directoryURL {
        case let .success(url):
            return "Git2.Repository: " + url.path
        case let .failure(error):
            return "Git2.Repository: ERROR " + error.localizedDescription
        }
    }
}

// Remotes
public extension Repository {
    func getRemoteFirst() -> Result<Remote, Error> {
        return remoteNameList()
            .flatMap { arr -> Result<Remote, Error> in
                if let first = arr.first {
                    return self.remoteRepo(named: first)
                }
                return .failure(WTF("can't get RemotesNames"))
            }
    }
    
    func getAllRemotesCount() -> Result<Int, Error>{
        remoteNameList()
            .map{ $0.count }
    }
    
    func remoteList() -> Result<[Remote], Error> {
        return remoteNameList()
            .flatMap { $0.flatMap { self.remoteRepo(named: $0) } }
    }

    func remoteNameList() -> Result<[String], Error> {
        var strarray = git_strarray()

        return git_try("git_remote_list") {
            git_remote_list(&strarray, self.pointer)
        } | { strarray.map { $0 } }
    }
}

public enum BranchBase { 
    case head
    case commit(Commit)
    case branch(Branch)
}

public extension Repository {
    func createReference(name: String, oid: OID, force: Bool, reflog: String)-> R<Reference> {
        var oid = oid.oid

        return git_instance(of: Reference.self, "git_reference_create") { pointer in
            git_reference_create(&pointer, self.pointer, name, &oid, force ? 1 : 0, reflog)
        }
    }
    
    @available(*, deprecated, message: "use createBranch(from target) instead. But this method works with detached head")
    // Works with detached head
    func createBranchOLD(from base: BranchBase, name: String, checkout: Bool) -> Result<Reference, Error> {
        
        switch base {
        case .head: return headCommit().flatMap { createBranch(from: $0, name: name, checkout: checkout) }
        case let .commit(c): return createBranch(from: c, name: name, checkout: checkout)
        case let .branch(b): return BranchTarget.branch(b).with(self).commit | { c in createBranch(from: c, name: name, checkout: checkout) }
        }
    }
    
    ///TODO: Does not work with detached head!!!!!
    func createBranch(from target: BranchTarget, name: String, checkout: Bool) -> Result<Reference, Error> {
        target.with(self).commit
            | { self.createBranch(from: $0, name: name, checkout: checkout)}
    }
    
    func branchLookup(name: String) -> R<Branch>{
        reference(name: name)
            .flatMap{ $0.asBranch() }
    }

    internal func createBranch(from commit: Commit, name: String, checkout: Bool, force: Bool = false) -> Result<Reference, Error> {
        var pointer: OpaquePointer?

        return git_try("git_branch_create") {
            git_branch_create(&pointer, self.pointer, name, commit.pointer, force ? 0 : 1)
        }
        .map { Reference(pointer!) }
        .if(checkout,
            then: { self.checkout(reference: $0, strategy: .Safe) })
    }

    func commit(message: String, signature: Signature) -> Result<Commit, Error> {
        return index()
            .flatMap { index in Duo(index, self).commit(message: message, signature: signature) }
    }

    func remoteRepo(named name: String) -> Result<Remote, Error> {
        return remoteLookup(named: name) { $0.map { Remote($0) } }
    }

    func remoteLookup<A>(named name: String, _ callback: (Result<OpaquePointer, Error>) -> A) -> A {
        var pointer: OpaquePointer?

        let result = _result((), pointOfFailure: "git_remote_lookup") {
            git_remote_lookup(&pointer, self.pointer, name)
        }.map { pointer! }

        return callback(result)
    }

    func remote(name: String) -> Result<Remote, Error> {
        var pointer: OpaquePointer?

        return git_try("git_remote_lookup") {
            git_remote_lookup(&pointer, self.pointer, name)
        }.map { Remote(pointer!) }
    }
}

public extension Repository {
    class func exists(at url: URL) -> Bool {
        if case .success(_) = at(url: url) {
            return true
        }
        return false
    }
    
    class func exists(at path: String) -> Bool {
        if case .success(_) = at(path: path) {
            return true
        }
        return false
    }
    
    class func at(path: String) -> Result<Repository, Error> {
        git_instance(of: Repository.self, "git_repository_open") { p in
            git_repository_open(&p, path)
        }
    }
    
    class func at(url: URL, fixDetachedHead: Bool = true) -> Result<Repository, Error> {
        var pointer: OpaquePointer?

        return git_try("git_repository_open") {
            url.withUnsafeFileSystemRepresentation {
                git_repository_open(&pointer, $0)
            }
        }
        .map { _ in Repository(pointer!) }
        .if(fixDetachedHead,
            then: { repo in repo.detachedHeadFix().map { _ in repo } })
    }

    class func create(at url: URL) -> Result<Repository, Error> {
        var pointer: OpaquePointer?

        return _result({ Repository(pointer!) }, pointOfFailure: "git_repository_init") {
            url.path.withCString { path in
                git_repository_init(&pointer, path, 0)
            }
        }
    }
}

// index
public extension Repository {
    ///Unstage files by relative path
    func resetDefault(pathPatterns: [String] = ["*"]) -> R<Void> {
        if self.headIsUnborn {
            return index()
                .flatMap{ $0.removeAll(pathPatterns: pathPatterns) }
        }
        
        return HEAD()
            | { $0.targetOID }
            | { self.commit(oid: $0) }
            | { resetDefault(commit: $0, paths: pathPatterns) }
    }
    
    func resetDefault(commit: Commit, paths: [String]) -> R<Void> {
        git_try("git_reset_default") {
            paths.with_git_strarray { strarray in
                git_reset_default(self.pointer, commit.pointer, &strarray)
            }
        }
    }
    
    func reset(_ resetType: ResetType, paths: [String] = []) -> R<Void> {
        BranchTarget.HEAD.with(self).commit | { self.reset(resetType, commit: $0, paths: paths) }
    }
    
    func reset(_ resetType: ResetType, commit: Commit, paths: [String], options: CheckoutOptions = CheckoutOptions()) -> R<Void> {
        git_try("git_reset") {
            options.with_git_checkout_options { options in
                paths.with_git_strarray { strarray in
                    if strarray.count > 0 {
                        options.paths = strarray
                    }
                    
                    return git_reset(self.pointer, commit.pointer, resetType.asGitResetType(), &options)
                }
            }
        }
    }
    
    func addBy(path: String) -> R<Repository> {
        index() | { $0.addBy(relPath: path) } | { self }
    }
    
    ///Stage files by relative path
    func add(relPaths: [String]) -> R<()> {
        index().flatMap { $0.addAll(pathPatterns: relPaths) }
    }
    
    func remove(relPaths: [String]) -> R<()> {
         index()
            .flatMap { $0.removeAll(pathPatterns: relPaths) }
    }
}

// Remote
public extension Repository {
    func createRemote(str: String) -> Result<Remote, Error> {
        var pointer: OpaquePointer?

        return _result({ Remote(pointer!) }, pointOfFailure: "git_remote_create") {
            "origin".withCString { tempName in
                str.withCString { url in
                    git_remote_create(&pointer, self.pointer, tempName, url)
                }
            }
        }
    }
}

// STATIC funcs
public extension Repository {
    static func clone(from remoteURL: URL, to localURL: URL, options: CloneOptions) -> Result<Repository, Error> {
        var pointer: OpaquePointer?
        let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString

        return git_try("git_clone") {
            options.with_git_clone_options { clone_options in
                localURL.withUnsafeFileSystemRepresentation { git_clone(&pointer, remoteURLString, $0, &clone_options) }
            }
        }.map { Repository(pointer!) }
    }
}

////////////////////////////////////////////////////////////////////
/// ERRORS
////////////////////////////////////////////////////////////////////

enum RepositoryError: Error {
    case FailedToGetRepoUrl
}

extension RepositoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FailedToGetRepoUrl:
            return "FailedToGetRepoUrl. Url is nil?"
        }
    }
}

///////////////////////////////////////////
/// STAGE and unstage all files
///////////////////////////////////////////
public extension Repository {
    /// stageAllFiles
    func addAllFiles() -> Result<(),Error> {
        return self.index() | { $0.addAll(pathPatterns: []) }
    }

    /// unstageAllFiles
    func resetAllFiles() -> Result<(),Error> {
        return self.index() | { _ in self.resetDefault(pathPatterns: []) }
    }
}

fileprivate extension Diff.Delta {
    func getFileAbsPathUsing(repoPath: String) -> String {
        return "\(repoPath)/" + ( (self.newFile?.path ?? self.oldFile?.path) ?? "" )
    }
}

public extension Repository {
    func headCommit() -> Result<Commit, Error> {
        var oid = git_oid()
        
        return _result({ oid }, pointOfFailure: "git_reference_name_to_id") {
            git_reference_name_to_id(&oid, self.pointer, "HEAD")
        }
        .flatMap { instanciate(OID($0)) }
    }
    
    func headBranch() -> R<Branch>{
        return self.HEAD()
            .flatMap { $0.asBranch() }
    }
    
    func headName() -> R<String> {
        if repoIsBare || headIsUnborn {
            return .success("master")
        }
        
        if headIsDetached {
            return HEAD()
                .flatMap{ $0.targetOID }
                .map { "\($0.description)".substring(to: 8) }
        }
        
        return HEAD()
            .map { $0.nameAsReference.replace(of: "refs/heads/", to: "") }
    }
}


public extension Repository {
    var State: RepoState {
        let state: Int32 = git_repository_state(self.pointer)
        
        return git_repository_state_t(UInt32(state))
            .asRepoState()
    }
    
    func stateClean() -> R<()> {
        return git_try("git_repository_state_cleanup") {
            git_repository_state_cleanup(self.pointer)
        }
    }
}

public extension Repository {
    // WTF two ignore checks

    func isIgnored(path: String) -> R<Bool> {
        var ignored : Int32 = 0
        return git_try("git_ignore_path_is_ignored") {
            git_ignore_path_is_ignored(&ignored, self.pointer, path)
        }.map { ignored == 1 }
    }
    
    func statusShouldIgnore(path: String) -> R<Bool> {
        var ignored : Int32 = 0
        return git_try("git_status_should_ignore") {
            git_status_should_ignore(&ignored, self.pointer, path)
        }.map { ignored == 1 }
    }
}

/////////////////
///HELPERS
///////////////////

public extension String {
    func asURL() -> URL {
        return URL(fileURLWithPath: self)
    }
}

public enum ResetType {
    case Soft
    case Mixed
    case Hard
    
    func asGitResetType() -> git_reset_t {
        switch self {
        case .Soft:
            return GIT_RESET_SOFT
        case .Mixed:
            return GIT_RESET_MIXED
        case .Hard:
            return GIT_RESET_HARD
        }
    }
}

public enum RepoState {
    case none,
         merge,
         revert,
         revertSequence,
         cherryPick,
         cherryPickSequence,
         bisect,
         rebase,
         rebaseInteractive,
         rebaseMerge,
         applyMailbox,
         applyMailboxOrRebase
    
    func asGitT() -> git_repository_state_t {
        switch self {
        case .none:
            return GIT_REPOSITORY_STATE_NONE
        case .merge:
            return GIT_REPOSITORY_STATE_MERGE
        case .revert:
            return GIT_REPOSITORY_STATE_REVERT
        case .revertSequence:
            return GIT_REPOSITORY_STATE_REVERT_SEQUENCE
        case .cherryPick:
            return GIT_REPOSITORY_STATE_CHERRYPICK
        case .cherryPickSequence:
            return GIT_REPOSITORY_STATE_CHERRYPICK_SEQUENCE
        case .bisect:
            return GIT_REPOSITORY_STATE_BISECT
        case .rebase:
            return GIT_REPOSITORY_STATE_REBASE
        case .rebaseInteractive:
            return GIT_REPOSITORY_STATE_REBASE_INTERACTIVE
        case .rebaseMerge:
            return GIT_REPOSITORY_STATE_REBASE_MERGE
        case .applyMailbox:
            return GIT_REPOSITORY_STATE_APPLY_MAILBOX
        case .applyMailboxOrRebase:
            return GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE
        }
    }
}

public extension git_repository_state_t {
    func asRepoState() -> RepoState{
        switch self {
        case GIT_REPOSITORY_STATE_NONE:
            return .none
        case GIT_REPOSITORY_STATE_MERGE:
            return .merge
        case GIT_REPOSITORY_STATE_REVERT:
            return .revert
        case GIT_REPOSITORY_STATE_REVERT_SEQUENCE:
            return .revertSequence
        case GIT_REPOSITORY_STATE_CHERRYPICK:
            return .cherryPick
        case GIT_REPOSITORY_STATE_CHERRYPICK_SEQUENCE:
            return .cherryPickSequence
        case GIT_REPOSITORY_STATE_BISECT:
            return .bisect
        case GIT_REPOSITORY_STATE_REBASE:
            return .rebase
        case GIT_REPOSITORY_STATE_REBASE_INTERACTIVE:
            return .rebaseInteractive
        case GIT_REPOSITORY_STATE_REBASE_MERGE:
            return .rebaseMerge
        case GIT_REPOSITORY_STATE_APPLY_MAILBOX:
            return .applyMailbox
        case GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE:
            return .applyMailboxOrRebase
        default:
            return .none
        }
    }
}
