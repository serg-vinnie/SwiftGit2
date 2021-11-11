//
//  Repository+Submodules.swift
//  SwiftGit2
//
//  Created by loki on 29.11.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension Repository {
    var childrenURLs : R<[URL]> {
        let url = self.directoryURL
        let paths = submodules().map { $0.map { $0.path } }
        return combine(url, paths).map { url, paths in paths.map { url.appendingPathComponent($0) } }
    }
    
    func submoduleName() -> Result<[String], Error> {
        var submodulePairs = SubmoduleCallbacks()

        return git_try("git_submodule_foreach") {
            git_submodule_foreach(self.pointer, submodulePairs.submodule_cb, &submodulePairs)
        }.map { submodulePairs.submodulesNames }
    }
    
    func submodules() -> Result<[Submodule], Error> {
        submoduleName().flatMap { names in names.flatMap { self.submoduleLookup(named: $0) } }
    }

    func submoduleLookup(named name: String) -> Result<Submodule, Error> {
        git_instance(of: Submodule.self, "git_submodule_lookup"){ p in
            git_submodule_lookup(&p, self.pointer, name)
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
        else {
            return -1
        }

        self_.submodulesNames.append(nameStr)

        return 0
    }
}
