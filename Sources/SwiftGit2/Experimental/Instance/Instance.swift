//
//  Instance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//
// Conflict Submodule Test1111111111111111
//

import Clibgit2
import Foundation

public protocol InstanceProtocol {
    var pointer: OpaquePointer { get }

    init(_ pointer: OpaquePointer)
}
