
import Foundation
import Essentials
import Clibgit2

// GitActions are high level wrappers which provide UI level API
// Typical action is a struct with only one stored property: RepoID

public struct GitRebase {
    let repoID : RepoID
    public init( _ repoID: RepoID) { self.repoID = repoID }
}

public extension GitRebase {

    
    internal func start(onto: ReferenceID, options: RebaseOptions = RebaseOptions()) -> R<Rebase> {
        let head = repoID.HEAD | { $0.asReference }
        let head_ac = head | { $0.annotatedCommit }
        let sync = head | { BranchSync.with(our: $0, their: onto) }
        let base = sync | { $0.base } | { CommitID(repoID: repoID, oid: $0) } | { $0.annotatedCommit }
        return combine(repoID.repo, onto.annotatedCommit, base, head_ac)
        | { repo, onto, base, head in
             repo.rebase(branch: head /* base */ /*no head*/, upstream: onto, onto: nil, options: options)
        }
    }
    
    // naming of functions rely on usage GitRebase(repoID).head(from: ref)
    func head(from ref: ReferenceID, signature: Signature) -> R<[OID]> {
        repoID.HEAD | { $0.asReference }
                    | { self.from(target: $0, upstream: ref, signature: signature) }
    }
    
    func from(target: ReferenceID, upstream: ReferenceID, options: RebaseOptions = RebaseOptions(), signature: Signature) -> R<[OID]> {
        combine(repoID.repo, target.annotatedCommit, upstream.annotatedCommit)
            .flatMap { repo, target, upstream in repo.rebase(branch: nil, upstream: upstream, onto: nil, options: options) }
            .flatMap { rebase in
                let oids = rebase.iterate(sigature: signature)
                return rebase.finish(signature: signature) | { _ in oids }
            }
//            | { $0.finish(signature: signature) }
        
    }
}

extension Repository {
    //
    // https://libgit2.org/libgit2/#HEAD/group/rebase/git_rebase_init
    //
    func rebase(branch: AnnotatedCommit?, upstream: AnnotatedCommit?, onto: AnnotatedCommit?, options: RebaseOptions) -> R<Rebase> {
        git_instance(of: Rebase.self, "git_rebase_init") { pointer in
            options.with_git_rebase_options { opt in
                git_rebase_init(&pointer, self.pointer, branch?.pointer, upstream?.pointer, onto?.pointer, &opt)
            }
        }
    }
}

