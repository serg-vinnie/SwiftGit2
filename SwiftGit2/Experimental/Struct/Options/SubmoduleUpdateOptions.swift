//
//  SubmoduleUpdateOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 10.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public class SubmoduleUpdateOptions {
    var options = git_submodule_update_options()
    private let fetch: FetchOptions
    private let checkout: CheckoutOptions

    public init(auth: Auth, block: @escaping TransferProgressCB) {
        self.fetch = FetchOptions(callbacks: RemoteCallbacks(auth: auth, transfer: block))
        self.checkout = CheckoutOptions()

        git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION))
    }
    
    public init(fetch: FetchOptions, checkout: CheckoutOptions = CheckoutOptions()) {
        self.fetch = fetch
        self.checkout = checkout
        git_submodule_update_options_init(&options, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION))
    }
    
    public static var defaultSSH : SubmoduleUpdateOptions {
        SubmoduleUpdateOptions(fetch: FetchOptions(auth: .credentials(.sshDefault)), checkout: CheckoutOptions(strategy: .Force, pathspec: [], progress: nil))
    }
}

extension SubmoduleUpdateOptions {
    func with_git_submodule_update_options<T>(_ body: (inout git_submodule_update_options) -> T) -> T {
        fetch.with_git_fetch_options { fetch_options in
            checkout.with_git_checkout_options { checkout_options in
                options.fetch_opts = fetch_options
                options.checkout_opts = checkout_options
                return body(&options)
            }
        }
    }
}
