
import Foundation
import Essentials
import Clibgit2

public struct GitRebase {
    let repoID : RepoID
}

extension GitRebase {
    
}

extension Repository {
    func rebaseInit(branch: AnnotatedCommit, upstream: AnnotatedCommit, onto: AnnotatedCommit, options: GitRebaseOptions) -> R<Rebase> {
        git_instance(of: Rebase.self, "git_rebase_init") { pointer in
            git_rebase_init(&pointer,self.pointer,branch.pointer, upstream.pointer, onto.pointer,&options.options)
        }
    }
}

public class Rebase: InstanceProtocol {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_rebase_free(pointer)
    }
}

class GitRebaseOptions {
    var options = git_rebase_options()
    let merge : MergeOptions
    
    init(merge: MergeOptions) {
        self.merge = merge
        git_rebase_options_init(&options, UInt32(GIT_REBASE_OPTIONS_VERSION))
        options.merge_options = merge.merge_options
    }
}

extension GitRebaseOptions {
    func with_git_rebase_options<T>(_ body: (inout git_rebase_options) -> T) -> T {
        body(&options)
    }
}
