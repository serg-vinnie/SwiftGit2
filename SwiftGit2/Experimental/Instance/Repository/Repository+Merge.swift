//
//  Repository+Merge.swift
//  SwiftGit2-OSX
//
//  Created by loki on 14.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials
import Foundation

public extension ReferenceID {
    func mergeFastForward() -> R<Void> {
        let ourID = repoID.headRefID
        let their = self
        return combine(ourID, repoID.repo).flatMap { ourID, repo in
            repo.mergeFastForward(our: ourID, their: their)
        } | { _ in () }
    }
}

extension RepoID {
    var headRefID : R<ReferenceID> { repo | { $0.headRefID } }
}

public extension Repository {
    var unbornReference : R<ReferenceID> {
        let name = self.directoryURL
        | { $0.appendingPathComponent(".git/HEAD").readToString }
        | { $0.dropFirst("ref: ".count) }
        | { String($0) }
        
        return combine(name, self.repoID) | { name, repoID in
            ReferenceID(repoID: repoID, name: name)
        }
    }
    
    var headRefID : R<ReferenceID> {
        if self.headIsUnborn {
            return unbornReference
        }
        
        return self.repoID | { $0.HEAD } | { $0.asReference }
    }
    
    func commit(branch: String) -> R<Commit> {
        reference(name: branch) | { $0.asBranch() } | { $0.targetOID } | { self.instanciate($0)}
    }
    
    func merge(from: String, into: String, signature: Signature) -> R<Commit> {
        return combine(commit(branch: from), commit(branch: into))
            .flatMap { c1, c2 in self.mergeAndCommit(our: c1, their: c2, msg: "Merge: \(from) -> \(into)", signature: signature)}
    }
    
    func mergeBase(one: OID, two: OID) -> Result<OID, Error> {
        var out = git_oid()

        return git_try("git_merge_base") {
            var one_ = one.oid
            var two_ = two.oid
            return git_merge_base(&out, self.pointer, &one_, &two_)
        }.map { OID(out) }
    }

    func merge(our: Tree, their: Tree, ancestor: Tree, options: MergeOptions) -> Result<Index, Error> {
        var options = options
        var indexPointer: OpaquePointer?

        return git_try("git_merge_trees") {
            git_merge_trees(&indexPointer, self.pointer, ancestor.pointer, our.pointer, their.pointer, &options.merge_options)
        }.map { Index(indexPointer!) }
    }

    func merge(our: Commit, their: Commit) -> Result<Index, Error> {
        var options = MergeOptions()
        var indexPointer: OpaquePointer?

        return git_try("git_merge_commits") {
            git_merge_commits(&indexPointer, self.pointer, our.pointer, their.pointer, &options.merge_options)
        }.map { Index(indexPointer!) }
    }

    func mergeAndCommit(our: Commit, their: Commit, msg: String, signature: Signature) -> Result<Commit, Error> {
        return merge(our: our, their: their)
            .flatMap { index in
                Duo(index, self)
                    .commit(message: msg, signature: signature)
            }
    }
    
    func mergeIntoHEAD(their theirName: String, signature: Signature, options: MergeOptions) -> Result<MergeResult, Error> {
        let our = HEAD()  | { $0.asBranch() }
        let their = self.branchLookup(name: theirName)
        let anal = their | { mergeAnalysis(branch: $0) }
        return combine(anal, our, their)
            | { self.mergeAndCommit(anal: $0, our: $1, their: $2, signature: signature, options: options) }
    }
    
    func mergeFastForward(our: ReferenceID, their: ReferenceID) -> R<Reference> {
        let targetOID = their.targetOID
        let message = "Fast Forward MERGE \(their.name) -> \(our.name)"
        let ref = our.reference
        return combine(their.targetOID, our.reference) | { oid, ref in
            ref.set(target: oid, message: message)
        }
    }
    
    func mergeAndCommit(anal: MergeAnalysis, our: Branch, their: Branch, signature: Signature, options: MergeOptions, stashing: Bool = false) -> Result<MergeResult, Error> {
        guard !anal.contains(.upToDate) else { return .success(.upToDate) }
        
        if anal.contains(.fastForward) || anal.contains(.unborn) {
            /////////////////////////////////////
            // FAST-FORWARD MERGE
            /////////////////////////////////////
            
            let targetOID = their.targetOID
            
            let message = "Fast Forward MERGE \(their.nameAsReference) -> \(our.nameAsReference)"

            return targetOID
                | { oid in our.set(target: oid, message: message) }
                | { $0.asBranch() }
                | { self.checkout(branch: $0, strategy: .Force, stashing: stashing) }
                | { _ in .fastForward }
            
        } else if anal.contains(.normal) {
            /////////////////////////////////
            // THREE-WAY MERGE
            /////////////////////////////////
            
            let ourOID   = our.targetOID
            let theirOID = their.targetOID
            let baseOID  = combine(ourOID, theirOID) | { self.mergeBase(one: $0, two: $1) }
            
            let message = baseOID
                | { base in "MERGE [\(their.nameAsReferenceCleaned)] & [\(our.nameAsReferenceCleaned)] | BASE: \(base)" }
            
            let ourTree   = ourOID   | { self.commit(oid: $0) } | { $0.tree() }
            let theirTree = theirOID | { self.commit(oid: $0) } | { $0.tree() }
            let baseTree  = baseOID  | { self.commit(oid: $0) } | { $0.tree() }
            
            let ourCommit   = ourOID   | { self.commit(oid: $0) }
            let theirCommit = theirOID | { self.commit(oid: $0) }
            let parents     = combine(ourCommit, theirCommit) | { [$0, $1] }
            
            let branchName = our.nameAsReference
            
            return combine(ourTree, theirTree, baseTree)
                .flatMap { self.merge(our: $0, their: $1, ancestor: $2,options: options) } // -> Index
                .if(\.hasConflicts,
                    then: { index in
                        parents
                            .map {
                                // MERGE_HEAD creation
                                let _ = RevFile( repo: self, type: .PullMsg)?
                                    .generatePullMsg(from: index)
                                    .save()
                                
                                // MERGE_MODE creation
                                let _ = RevFile(repo: self, type: .MergeMode )?
                                    .save()
                                
                                // MERGE_HEAD creation
                                OidRevFile( repo: self, type: .MergeHead)?
                                    .setOid(from: $0[1] )
                                    .save()
                            } | { _ in
                                self.checkout(index: index, strategy: [.Force, .AllowConflicts, .ConflictStyleMerge, .ConflictStyleDiff3])
                                    | { _ in .success(.threeWayConflict(index)) }
                            }
                    },
                    else: { index in
                        combine(message, parents)
                            | { index.commit(into: self, signature: signature, message: $0, parents: $1) }
                            | { _ in self.checkout(ref: branchName, strategy: .Force, stashing: false) }
                            | { _ in .threeWaySuccess }
                    })
            
        }
            
        return .failure(WTF("pull: unexpected MergeAnalysis value: \(anal.rawValue)"))
    }

    func mergeAnalysisUpstream(_ target: BranchTarget) -> R<MergeAnalysis> {
        target.branch(in: self)
            | { $0.upstream() }
            | { $0.targetOID }
            | { self.annotatedCommit(oid: $0) }
            | { self.mergeAnalysis(their_head: $0) }
    }
    
    func mergeAnalysis(branch: Branch) -> R<MergeAnalysis> {
        branch.targetOID
            | { self.annotatedCommit(oid: $0) }
            | { self.mergeAnalysis(their_head: $0) }
    }

    // Analyzes the given branch(es) and determines the opportunities for merging them into the HEAD of the repository.
    func mergeAnalysis(their_head: AnnotatedCommit) -> Result<MergeAnalysis, Error> {
        var anal = git_merge_analysis_t.init(0)
        var pref = git_merge_preference_t.init(0)
        var their_heads: OpaquePointer? = their_head.pointer

        return git_try("git_merge_analysis") {
            git_merge_analysis(&anal, &pref, self.pointer, &their_heads, 1)
        }.map { MergeAnalysis(rawValue: anal.rawValue) }
    }
}



public class AnnotatedCommit: InstanceProtocol {
    public var pointer: OpaquePointer
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_annotated_commit_free(pointer)
    }
}

public extension Repository {
    func annotatedCommit(oid: OID) -> Result<AnnotatedCommit, Error> {
        var pointer: OpaquePointer?
        var _oid = oid.oid

        return _result({ AnnotatedCommit(pointer!) }, pointOfFailure: "git_annotated_commit_lookup") {
            git_annotated_commit_lookup(&pointer, self.pointer, &_oid)
        }
    }
}

public struct MergeAnalysis: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32

    public static let none = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NONE.rawValue) // No merge is possible.  (Unused.)
    public static let normal = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_NORMAL.rawValue) // A "normal" merge; both HEAD and the given merge input have diverged from their common ancestor. The divergent commits must be merged.
    public static let upToDate = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UP_TO_DATE.rawValue) // All given merge inputs are reachable from HEAD, meaning the repository is up-to-date and no merge needs to be performed.
    public static let fastForward = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_FASTFORWARD.rawValue) // The given merge input is a fast-forward from HEAD and no merge needs to be performed. Instead, the client can check out the given merge input.
    public static let unborn = MergeAnalysis(rawValue: GIT_MERGE_ANALYSIS_UNBORN.rawValue) // The HEAD of the current repository is "unborn" and does not point to a valid commit. No merge can be performed, but the caller may wish to simply set HEAD to the target commit(s).
}

public struct MergePreference: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public let rawValue: UInt32

    public static let none = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NONE.rawValue) // No configuration was found that suggests a preferred behavior for merge.
    public static let noFastForward = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_NO_FASTFORWARD.rawValue) // There is a merge.ff=false configuration setting, suggesting that the user does not want to allow a fast-forward merge.
    public static let fastForwardOnly = MergeAnalysis(rawValue: GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY.rawValue) // There is a merge.ff=only configuration setting, suggesting that the user only wants fast-forward merges.
}

