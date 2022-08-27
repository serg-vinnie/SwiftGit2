import Foundation
import Essentials
import Clibgit2

public struct GitStash {
    public let repoID: RepoID
    public init(repoID: RepoID) { self.repoID = repoID }
}

public extension GitStash {
    func save(signature: Signature, message: String?, flags: StashFlags = .defaultt ) -> R<OID>  {
        return repoID.repo
            .flatMap { $0.stashSave(signature: signature, message: message, flags: flags) }
    }
    
    func apply(stashIdx: Int, options: StashApplyOptions = StashApplyOptions()) -> R<()> {
        repoID.repo
            .flatMap { $0.stashApply(stashIdx:stashIdx, options: options) }
            .flatMapError { err in
                if err.isGit2(func: "git_stash_apply", code: -22) {
                    return repoID.repo | { repo in repo.unStage(.all) | { _ in repo.stashApply(stashIdx: stashIdx, options: options) } }
                } else {
                    return .failure(err)
                }
            }
    }
    
    func item(oid: OID) -> R<Stash> {
        items() | { $0.first { $0.id == oid }.asNonOptional }
    }
    
    func pop(oid: OID, options: StashApplyOptions = StashApplyOptions()) -> R<()> {
        combine(repoID.repo, item(oid: oid)) | { repo, item in repo.stashPop(idx: item.index, options: options) }
    }
    
    func items() -> R<[Stash]> {
        return repoID.repo
            .flatMap { $0.stashForeach() }
    }
    
    func remove(stashIdx: Int) -> R<()> {
        return repoID.repo
            .flatMap { $0.stashDrop(stashIdx: stashIdx) }
    }
}

internal extension Repository {
    func stashForeach() -> R<[Stash]> {
        var cb = StashCallbacks()
        
        return _result( { cb.stashes } , pointOfFailure: "git_stash_foreach") {
            git_stash_foreach(self.pointer, cb.git_stash_cb, &cb)
        }
    }
    
    func stashSave(signature: Signature, message: String?, flags: StashFlags ) -> R<OID> {
        var oid: git_oid = git_oid() // out
        
        if let message = message {
            return signature.make()
                .flatMap { signat in
                    git_try("git_stash_save") {
                        message.withCString { msg in
                            git_stash_save(&oid, self.pointer, signat.pointer, msg, flags.rawValue)
                        }
                    }
                }
                .map { _ in OID(oid) }
        }
        
        return signature.make()
            .flatMap { signat in
                git_try("git_stash_save") {
                    git_stash_save(&oid, self.pointer, signat.pointer, nil, flags.rawValue)
                }
            }
            .map { _ in OID(oid) }
    }
    
    func stashApply(stashIdx: Int, options: StashApplyOptions) -> R<()> {
        git_try("git_stash_apply") {
            options.with_git_stash_apply_options { opt in
                git_stash_apply(self.pointer, stashIdx, &opt)
            }
            
        }
    }
    
    func stashPop(idx: Int, options: StashApplyOptions) -> R<()> {
        git_try("git_stash_pop") {
            options.with_git_stash_apply_options { opt in
                git_stash_pop(self.pointer, idx, &opt)
            }
        }
    }
    
    func stashDrop(stashIdx: Int) -> R<()> {
        return _result( { () } , pointOfFailure: "git_stash_drop") {
            git_stash_drop(self.pointer, stashIdx)
        }
    }
}
