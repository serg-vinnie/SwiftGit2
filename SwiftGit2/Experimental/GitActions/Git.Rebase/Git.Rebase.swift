
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
        case .HEAD:                 return repoID.repo | { repo in repo.headOID() | { repo.annotatedCommit(oid: $0) } }
        case .ref(let refID):       return refID.annotatedCommit
        case .commit(let comID):    return comID.annotatedCommit
        }
    }
}

extension Array where Element == OID {
    func checkingout(refID: ReferenceID) -> R<[OID]> {
        if let oid = self.last {
            return refID.set(target: oid, message: "rebase (finish): \(refID.name) onto \(oid.description)")
                .flatMap { _ in refID.checkout(options: .init(strategy: .Force)) }
                .map { _ in self }
        }
        return .success(self)
    }
}

public extension GitRebase {
    enum Target {
        case HEAD
        case ref(ReferenceID)
        case commit(CommitID)
    }
        
    func run(src: Target, dst: ReferenceID, signature: Signature, options: RebaseOptions = RebaseOptions()) -> R<[OID]> {
        let src_ac = src.annotatedCommit(in: repoID)
        let dst_ac = dst.annotatedCommit
        let dst_ref = dst
        
        
        return combine(repoID.repo, src_ac, dst_ac) | { repo, src, dst in
            repo.rebase(branch: src, upstream: dst, onto: nil, options: options)
                .flatMap { rebase in
                    let oids = rebase.iterate(repo: repo, sigature: signature, options: options)
                    if case let .failure(error) = oids {
                        return .failure(error) // rebase will not be finalized
                    }
                    return rebase.finish(signature: signature)
                            | { _ in oids }
                            | { $0.checkingout(refID: dst_ref) }
                }
        }
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

