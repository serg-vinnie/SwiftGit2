//
//  Repository+Submodules.swift
//  SwiftGit2
//
//  Created by loki on 29.11.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public extension Repository {
    func submodules() -> Result<[Submodule], Error> {
        var submodulePairs = SubmoduleCallbacks()

        return _result({ submodulePairs.submodulesNames }, pointOfFailure: "git_submodule_foreach") {
            git_submodule_foreach(self.pointer, submodulePairs.submodule_cb, &submodulePairs)
        }
        .flatMap { names in names.flatMap { self.submoduleLookup(named: $0) } }
    }

    func submoduleLookup(named name: String) -> Result<Submodule, Error> {
        var subModPointer: OpaquePointer?

        return _result({ Submodule(subModPointer!) }, pointOfFailure: "git_submodule_lookup") {
            name.withCString { submoduleName in
                git_submodule_lookup(&subModPointer, self.pointer, submoduleName)
            }
        }
    }
}

class SubmoduleCallbacks {
    var submodulesNames = [String]()

    let submodule_cb: git_submodule_cb = { _, name, payload in
        let self_ = payload.unsafelyUnwrapped
            .bindMemory(to: SubmoduleCallbacks.self, capacity: 1)
            .pointee

        guard let name = name,
              let nameStr = String(utf8String: name)
        else { return -1 }

        self_.submodulesNames.append(nameStr)

        return 0
    }
}
