
import Clibgit2
import Foundation

public class CloneOptions {
    var clone_options = git_clone_options()

    let fetch: FetchOptions
    let checkout: CheckoutOptions

    var bare: Bool {
        set { clone_options.bare = newValue ? 1 : 0 }
        get { return clone_options.bare == 1 }
    }

    public init(fetch: FetchOptions, checkout: CheckoutOptions = CheckoutOptions()) {
        self.fetch = fetch
        self.checkout = checkout

        git_clone_init_options(&clone_options, UInt32(GIT_CLONE_OPTIONS_VERSION))
    }
    
    public static var defaultSSH : CloneOptions { CloneOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil)) }
}

extension CloneOptions {
    func with_git_clone_options<T>(_ body: (inout git_clone_options) -> T) -> T {
        fetch.with_git_fetch_options { fetch_options in
            checkout.with_git_checkout_options { checkout_options in

                clone_options.fetch_opts = fetch_options
                clone_options.checkout_opts = checkout_options

                return body(&clone_options)
            }
        }
    }
}
