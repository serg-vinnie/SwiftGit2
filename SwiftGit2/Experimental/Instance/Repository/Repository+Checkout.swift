//
//  RepositoryCheckout.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public extension RepoID {
    func checkout(index: Index, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> R<Void> {
        (repo | { $0.checkout(index: index, strategy: strategy, progress: progress) })
    }
}


// SetHEAD and Checkout
public extension Repository {
    func checkout(ref name: String, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil, stashing: Bool) -> Result<Void, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            reference(name: name)
                .flatMap { $0.asBranch() }
                .flatMap { self.checkout(branch: $0, strategy: strategy, progress: progress, stashing: stashing) }
        }
    }

    func checkout(branch: Branch, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil, pathspec: [String] = [], stashing: Bool) -> Result<Void, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            setHEAD(branch.nameAsReference)
                .flatMap { self.checkoutHead(strategy: strategy, progress: progress, pathspec: pathspec) }
        }
    }

    func checkout(commit: Commit, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil, pathspec: [String], stashing: Bool) -> Result<Void, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            checkout(commit.oid, strategy: strategy, progress: progress, pathspec: pathspec, stashing: stashing) | { _ in () }
        }
    }
    
    func checkout(_ oid: OID, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil, pathspec: [String] = [], stashing: Bool) -> Result<Repository, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            setHEAD_detached(oid)
                | { checkoutHead(strategy: strategy, progress: progress, pathspec: pathspec) }
                | { self }
        }
    }
    

    
    func checkout(reference: Reference, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil, pathspec: [String], stashing: Bool) -> Result<Reference, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            setHEAD(reference.nameAsReference)
                .flatMap { checkoutHead(strategy: strategy, progress: progress, pathspec: pathspec) }
                .map { reference }
        }
    }


}

public extension Repository {
    func setHEAD_detached(_ oid: OID) -> Result<Void, Error> {
        var oid = oid.oid
        return _result((), pointOfFailure: "git_repository_set_head_detached") {
            git_repository_set_head_detached(self.pointer, &oid)
        }
    }

    func setHEAD(_ reference: String) -> Result<Void, Error> {
        let refID = self.repoID | { ReferenceID(repoID: $0, name: reference) }
        guard let ref = refID.maybeSuccess, ref.exists else { return .wtf("reference not exist, can't checkout: \(reference)") }
        
        return _result((), pointOfFailure: "git_repository_set_head") {
            return git_repository_set_head(self.pointer, reference)
        }
    }
    
    internal func checkoutHead(options: CheckoutOptions, stashing: Bool) -> Result<Void, Error> {
        GitStasher(repo: self).wrap(skip: !stashing) {
            self.checkoutHead(options: options)
        }
    }
    
    func checkoutHead(options: CheckoutOptions) -> Result<Void, Error> {
        git_try("git_checkout_head") {
            options.with_git_checkout_options {
                git_checkout_head(self.pointer, &$0)
            }
        }
    }
    
    internal func checkoutHead(strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil, pathspec: [String]) -> Result<Void, Error> {
        return git_try("git_checkout_head") {
            CheckoutOptions(strategy: strategy, pathspec: pathspec, progress: progress)
                .with_git_checkout_options { git_checkout_head(self.pointer, &$0) }
        }
    }

    func checkout(index: Index, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        let options = CheckoutOptions(strategy: strategy, progress: progress)
        
        return git_try("git_checkout_index") {
            options.with_git_checkout_options { opt in
                git_checkout_index(self.pointer, index.pointer, &opt)
            }
        }
    }
    
    func checkout(index: Index, strategy: CheckoutStrategy, relPaths: [String], progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        let options = CheckoutOptions(strategy: strategy,pathspec: relPaths, progress: progress )
        
        return git_try("git_checkout_index") {
            options.with_git_checkout_options { opt in
                git_checkout_index(self.pointer, index.pointer, &opt)
            }
        }
    }
}

////////////////////////////
//HELPERS
////////////////////////////
class FS {
    static func delete(_ path : String, silent: Bool = true) {
        if !silent {
            print("FS: going to delete file: \(path)")
        }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: path)
        } catch let error {
            if !silent {
                print("FS: cant delete \(path)")
                print(error)
            }
        }
    }

}
