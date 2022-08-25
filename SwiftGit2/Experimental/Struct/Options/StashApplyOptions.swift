//
//  StashApplyOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.08.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class StashApplyOptions {
    private var options = git_stash_apply_options()
    let checkout : CheckoutOptions
    
    public init(checkout : CheckoutOptions = CheckoutOptions(), flags: Flags = [.default]) {
        self.checkout = checkout
        git_stash_apply_options_init(&options, UInt32(GIT_STASH_APPLY_OPTIONS_VERSION))
        options.flags = flags.rawValue
    }
}

internal extension StashApplyOptions {
    func with_git_stash_apply_options<T>(_ body: (inout git_stash_apply_options) -> T) -> T {
        self.checkout.with_git_checkout_options { chOpt in
            self.options.checkout_options = chOpt
            return body(&options)
        }
    }
}


public extension StashApplyOptions {
    struct Flags: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public let rawValue: UInt32

        public static let `default`         = Flags(rawValue: GIT_STASH_APPLY_DEFAULT.rawValue)
        public static let reinstateIndex    = Flags(rawValue: GIT_STASH_APPLY_REINSTATE_INDEX.rawValue)
        
    }
}
