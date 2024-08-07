//
//  Submodule.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 06.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public class Submodule: InstanceProtocol {
    public let pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_submodule_free(pointer)
    }
}

public extension Submodule {
    var name: String { String(cString: git_submodule_name(pointer)) }
    /// Get the path to the submodule. RELATIVE! Almost allways the same as "name" parameter
    var path: String { String(cString: git_submodule_path(pointer)) }

    var absURL : R<URL> {
        self.repo() | { $0.directoryURL }
    }
    /// Url to remote repo (https or ssh)
    var url: String? {
        if let str = git_submodule_url(pointer) {
            return String(cString: str)
        }
        return nil
    }

    /// Get the OID for the submodule in the current working directory.
    var Oid: OID? {
        guard let submod = git_submodule_wd_id(pointer) else { return nil }
        
        return OID(submod.pointee)
    }

    /// Get the OID for the submodule in the current HEAD tree.
    var headOID: OID? {
        guard let submod = git_submodule_head_id(pointer) else { return nil }
        
        return OID(submod.pointee)
    }

    /// Open the repository for a submodule.
    /// WILL WORK ONLY IF SUBMODULE IS CHECKED OUT INTO WORKING DIRECTORY
    func repo() -> Result<Repository, Error> {
        git_instance(of: Repository.self, "git_submodule_open") { pointer in
            git_submodule_open(&pointer, self.pointer)
        }
    }

    func repoExist() -> Bool { (try? repo().get()) != nil }
}

public extension Duo where T1 == Submodule, T2 == Repository {
    /// Repository must be PARENT of submodule
    func getSubmoduleStatus() -> Result<SubmoduleStatusFlags, Error> {
        let (submodule, parentRepo) = value

        let ignore = git_submodule_ignore_t.init(SubmoduleIgnore.none.rawValue)

        var result = UInt32(0)

        return _result({ SubmoduleStatusFlags(rawValue: result) }, pointOfFailure: "git_submodule_status") {
            submodule.name.withCString { submoduleName in
                git_submodule_status(&result, parentRepo.pointer, submoduleName, ignore)
            }
        }
    }

    func getSubmoduleAbsPath() -> Result<String, Error> {
        let (submodule, repo) = value

        return repo.directoryURL.flatMap { url in
            .success("\(url.path)/\(submodule.path)")
        }
    }

    func fetchRecurseValueSet(_ bool: Bool) -> Result<Void, Error> {
        let (submodule, repo) = value

        let valToSet = git_submodule_recurse_t(rawValue: bool ? 1 : 0)

        return _result({ () }, pointOfFailure: "git_submodule_set_fetch_recurse_submodules") {
            submodule.name.withCString { submoduleName in
                git_submodule_set_fetch_recurse_submodules(repo.pointer, submoduleName, valToSet)
            }
        }
    }

    // TODO: Test Me -- this must be string or Branch?
    func branchGet() -> String {
        let (submodule, _) = value

        if let brPointer = git_submodule_branch(submodule.pointer) {
            return String(cString: brPointer)
        }

        return ""
    }

    // TODO: Test Me
    /// Set the branch for the submodule in the configuration
    func branchSetAndSync(branchName: String) -> Result<Void, Error> {
        let (submodule, repo) = value

        return _result({ () }, pointOfFailure: "git_submodule_set_branch") {
            branchName.withCString { brName in
                submodule.name.withCString { submoduleName in
                    git_submodule_set_branch(repo.pointer, submoduleName, brName)
                }
            }
        }
        .flatMap { submodule.sync() }
    }

    // WTF? What this fucking THING is doing? I have no idea.
    //   .resolveUrl() -> "git@gitlab.com:sergiy.vynnychenko/AppCore.git"
    //            .url -> "git@gitlab.com:sergiy.vynnychenko/AppCore.git"
    //
    // Resolve a submodule url relative to the given repository.
//    func resolveUrl() -> Result<String, Error> {
//        let (submodule, repo) = value
//
//        // let buf_ptr = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
//        var buf = git_buf(ptr: nil, asize: 0, size: 0)
//
//        return _result({ Buffer(buf: buf) }, pointOfFailure: "git_submodule_resolve_url") {
//            submodule.url.withCString { relativeUrl in
//                git_submodule_resolve_url(&buf, repo.pointer, relativeUrl)
//            }
//        }
//        .flatMap { $0.asString() }
//    }

    // TODO: Test Me
    /// Set the URL for the submodule in the configuration
    func submoduleSetUrlAndSync(newRelativeUrl: String) -> Result<Void, Error> {
        let (submodule, repo) = value

        return _result({ () }, pointOfFailure: "git_submodule_set_url") {
            submodule.name.withCString { submoduleName in
                newRelativeUrl.withCString { newUrl in
                    git_submodule_set_url(repo.pointer, submoduleName, newUrl)
                }
            }
        }
        .flatMap {
            submodule.sync()
        }
    }
}

public extension Submodule {
    
    // ACHTUNG  !!!!!!!
    // ACHTUNG: keep reference to parent repository during function call
    // ACHTUNG  !!!!!!!
    func cloned(options: SubmoduleUpdateOptions) -> R<Submodule> {
        clone(options: options).map { _ in self }
    }
    
    func clone(options: SubmoduleUpdateOptions) -> R<Repository> {
        return git_instance(of: Repository.self, "git_submodule_clone") { pointer in
            options.with_git_submodule_update_options { options in
                git_submodule_clone(&pointer, self.pointer, &options)
            }
        }
    }

    func fetchRecurseValueGet() -> Bool {
        // "result == 1"
        return git_submodule_fetch_recurse_submodules(pointer) == git_submodule_recurse_t(rawValue: 1)
    }

    // TODO: Test Me
    /// Copy submodule remote info into submodule repo.
    func sync() -> R<Void> {
        git_try("git_submodule_sync") { git_submodule_sync(self.pointer) }
    }

    // TODO: Test Me. // don't know how to test
    /// Reread submodule info from config, index, and HEAD |
    /// Call this to reread cached submodule information for this submodule if you have reason to believe that it has changed.
    func reload(force: Bool = false) -> Result<Void, Error> {
        let forceInt: Int32 = force ? 1 : 0

        return _result({ () }, pointOfFailure: "git_submodule_reload") {
            git_submodule_reload(self.pointer, forceInt)
        }
    }

    // TODO: Test Me.
    /// Update a submodule.
    /// This will clone a missing submodule and checkout the subrepository to the commit specified in the index of the containing repository.
    /// If the submodule repository doesn't contain the target commit (e.g. because fetchRecurseSubmodules isn't set),
    /// then the submodule is fetched using the fetch options supplied in options.
    func update(options: SubmoduleUpdateOptions, `init`: Bool = false) -> R<Void>
    {
        git_try("git_submodule_update") {
            options.with_git_submodule_update_options { opt in
                git_submodule_update(self.pointer, `init` ? 1 : 0, &opt)
            }
        }
    }

    // TODO: Test Me --- not sure how to test
    /// Add current submodule HEAD commit to index of superproject.
    /// writeIndex -- if true - should immediately write the index file. If you pass this as false, you will have to get the git_index and explicitly call `git_index_write()` on it to save the change
    func addToIndex(writeIndex: Bool = true) -> Result<Void, Error> {
        let writeIndex: Int32 = writeIndex ? 1 : 0

        return _result({ () }, pointOfFailure: "git_submodule_add_to_index") {
            git_submodule_add_to_index(self.pointer, writeIndex)
        }
    }

    // TODO: Test Me
    /// Resolve the setup of a new git submodule. |
    /// This should be called on a submodule once you have called add setup and done the clone of the submodule.
    /// This adds the .gitmodules file and the newly cloned submodule to the index to be ready to be committed (but doesn't actually do the commit).
    func add_finalize() -> R<Void> {
        git_try("git_submodule_add_finalize") {
            git_submodule_add_finalize(self.pointer)
        }
    }

    // TODO: Test Me. Especially "overwrite"
    func `init`(overwrite: Bool) -> R<Submodule> {
        git_try("git_submodule_init") {
            git_submodule_init(self.pointer, overwrite ? 1 : 0)
        } | { self }
    }
}

/// git_submodule_ignore_t;
public enum SubmoduleIgnore: Int32 {
    case unspecified = -1 // GIT_SUBMODULE_IGNORE_UNSPECIFIED  = -1, /**< use the submodule's configuration */
    case none = 1 // GIT_SUBMODULE_IGNORE_NONE      = 1,  /**< any change or untracked == dirty */
    case untracked = 2 // GIT_SUBMODULE_IGNORE_UNTRACKED = 2,  /**< dirty if tracked files change */
    case ignoreDirty = 3 // GIT_SUBMODULE_IGNORE_DIRTY     = 3,  /**< only dirty if HEAD moved */
    case ignoreAll = 4 // GIT_SUBMODULE_IGNORE_ALL       = 4,  /**< never dirty */
}

/// git_submodule_recurse_t;
public enum SubmoduleRecurse: UInt32 {
    case RecurseNo = 0 // GIT_SUBMODULE_RECURSE_NO
    case RecurseYes = 1 // GIT_SUBMODULE_RECURSE_YES
    case RecurseOnDemand = 2 // GIT_SUBMODULE_RECURSE_ONDEMAND
}

public struct SubmoduleStatusFlags: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32

    public static let InHead = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_IN_HEAD.rawValue)
    public static let InIndex = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_IN_INDEX.rawValue)
    public static let InConfig = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_IN_CONFIG.rawValue)
    public static let InWd = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_IN_WD.rawValue)
    public static let IndexAdded = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_INDEX_ADDED.rawValue)
    public static let IndexDeleted = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_INDEX_DELETED.rawValue)
    public static let IndexModified = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_INDEX_MODIFIED.rawValue)
    public static let WdUninitialized = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_UNINITIALIZED.rawValue)
    public static let WdAdded = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_ADDED.rawValue)
    public static let WdDeleted = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_DELETED.rawValue)
    public static let WdModified = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_MODIFIED.rawValue)
    public static let WdIndexModified = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_INDEX_MODIFIED.rawValue)
    public static let WdWdModified = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_WD_MODIFIED.rawValue)
    public static let WdUntracked = SubmoduleStatusFlags(rawValue: GIT_SUBMODULE_STATUS_WD_UNTRACKED.rawValue)
}

/*
 UNUSED:
 	git_submodule_add_setup
 	git_submodule_clone
 	git_submodule_ignore -- need to use SubmoduleIgnore enum here
 	git_submodule_set_ignore
 	git_submodule_repo_init
 	git_submodule_set_update
 	git_submodule_update_strategy
 	git_submodule_owner -- NEVER USE THIS SHIT. It's killing pointer too fast for you, buddy
 */
