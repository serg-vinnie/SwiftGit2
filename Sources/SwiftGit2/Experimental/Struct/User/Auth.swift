//
//  Auth.swift
//  SwiftGit2-OSX
//
//  Created by loki on 11.03.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public typealias AuthCB = (_ url: String?, _ username: String?) -> (Credentials)

public enum Auth {
    case match(AuthCB)
    case credentials(Credentials)
    case list([Credentials])
}

public extension Auth {
    static var defaultSSH : Auth {
        switch Credentials.sshAll {
        case let .success(creds):
            return Auth.list(creds)
        default:
            return Auth.credentials(.none)
        }
    }
}
