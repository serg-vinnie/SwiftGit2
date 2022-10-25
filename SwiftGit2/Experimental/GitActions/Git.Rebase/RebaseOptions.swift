import Foundation
import Essentials
import Clibgit2

public class RebaseOptions {
    var options     = git_rebase_options()
    let merge       : MergeOptions
    let checkout    : CheckoutOptions
    
    public init(merge: MergeOptions = MergeOptions(), checkout: CheckoutOptions = CheckoutOptions()) {
        self.merge = merge
        self.checkout = checkout
        git_rebase_options_init(&options, UInt32(GIT_REBASE_OPTIONS_VERSION))
        
        options.merge_options = merge.merge_options // merge options can be copied as is
                                                    // checkout options should be used through a wrapper
    }
}

extension RebaseOptions {
    func with_git_rebase_options<T>(_ body: (inout git_rebase_options) -> T) -> T {
        checkout.with_git_checkout_options { ch_opt in
            self.options.checkout_options = ch_opt
            return body(&options)
        }
    }
}
