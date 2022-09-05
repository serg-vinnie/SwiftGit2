import Foundation
import Essentials
import Clibgit2

class RebaseOptions {
    var options = git_rebase_options()
    let merge : MergeOptions
    
    init(merge: MergeOptions) {
        self.merge = merge
        git_rebase_options_init(&options, UInt32(GIT_REBASE_OPTIONS_VERSION))
        options.merge_options = merge.merge_options
    }
}

extension RebaseOptions {
    func with_git_rebase_options<T>(_ body: (inout git_rebase_options) -> T) -> T {
        body(&options)
    }
}
