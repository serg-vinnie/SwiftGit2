
import Foundation
import Essentials
import Clibgit2

// GitActions are high level wrappers which provide UI level API
// Typical action is a struct with only one stored property: RepoID

public struct GitRebase {
    let repoID : RepoID
    public init( _ repoID: RepoID) { self.repoID = repoID }
}

extension GitRebase.Target {
    func annotatedCommit(in repoID: RepoID) -> R<AnnotatedCommit> {
        switch self {
        case .HEAD:                 
            let t = repoID.repo | { $0.HEAD() } | { $0.target }
            
            return .notImplemented
        case .ref(let refID):       return .notImplemented
        case .commit(let comID):    return .notImplemented
        }
    }
}

public extension GitRebase {
    enum Target {
        case HEAD
        case ref(ReferenceID)
        case commit(CommitID)
    }
    
    enum CheckoutTarget {
        case src
        case dst
    }
    
    func run(src: Target, dst: Target, checkout: CheckoutTarget, signature: Signature, options: RebaseOptions = RebaseOptions()) -> R<[OID]> {
        
        
        return .notImplemented
    }
    
    // naming of functions rely on usage GitRebase(repoID).head(from: ref)
    func head(source: ReferenceID, signature: Signature) -> R<[OID]> {
        repoID.HEAD | { $0.asReference }
                    | { head in self.from(branch: source, upstream: head, signature: signature) }
    }
    
    func from(branch: ReferenceID, upstream: ReferenceID, options: RebaseOptions = RebaseOptions(), signature: Signature) -> R<[OID]> {
        combine(repoID.repo, branch.annotatedCommit, upstream.annotatedCommit)
            .flatMap { repo, branch, upstream in
                repo.rebase(branch: branch, upstream: upstream, onto: nil, options: options)
                    .flatMap { rebase in
                        let oids = rebase.iterate(repo: repo, sigature: signature, options: options)
                        return rebase.finish(signature: signature) | { _ in oids }
                    }
            }
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

