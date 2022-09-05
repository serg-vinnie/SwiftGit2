
import Foundation
import Essentials
import Clibgit2

public struct GitRebase {
    let repoID : RepoID
}

extension GitRebase {
    
}

extension Repository {
    func rebaseInit(branch: AnnotatedCommit, upstream: AnnotatedCommit, onto: AnnotatedCommit, options: RebaseOptions) -> R<Rebase> {
        git_instance(of: Rebase.self, "git_rebase_init") { pointer in
            git_rebase_init(&pointer,self.pointer,branch.pointer, upstream.pointer, onto.pointer,&options.options)
        }
    }
}


