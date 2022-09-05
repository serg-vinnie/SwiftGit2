
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
    // naming of functions rely on usage GitRebase(repoID).head(from: ref)
    func head(from ref: ReferenceID) -> R<()> {
        repoID.repo | { $0.HEAD() }
                    | { ReferenceID(repoID: repoID, name: $0.nameAsReference) }
                    | { self.from(ref, onto: $0) }
    }
    
    func from( _ ref: ReferenceID, onto: ReferenceID, options: RebaseOptions = RebaseOptions()) -> R<()> {
        combine(repoID.repo, ref.annotatedCommit, onto.annotatedCommit)
            | { repo, branch, onto in repo.rebase(branch: branch, upstream: nil, onto: onto, options: options) }
            | { $0.iterate() }
    }
}

extension Repository {
    func rebase(branch: AnnotatedCommit?, upstream: AnnotatedCommit?, onto: AnnotatedCommit?, options: RebaseOptions) -> R<Rebase> {
        git_instance(of: Rebase.self, "git_rebase_init") { pointer in
            options.with_git_rebase_options { opt in
                git_rebase_init(&pointer, self.pointer, branch?.pointer, upstream?.pointer, onto?.pointer, &opt)
            }
        }
    }
}

