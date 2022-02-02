//
//  RevisionWalker.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 05.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//
import Clibgit2
import Foundation
import Essentials


public extension Repository {
    // TODO: Optimize to use OIDs instead of Commit
    func pendingCommitsOIDs(_ target: BranchTarget, _ direction: Direction) -> R<[OID]> {
        let branch = target.branch(in: self)
        let branchName = branch | { $0.nameAsReference }
        let upstreamName = branch | { $0.upstream() } | { $0.nameAsReference }
        
        if direction == .push && branchName.maybeSuccess != nil && upstreamName.maybeFailure != nil {
            return branchName | { branch in Revwalk.new(in: self) | { $0.push(ref: branch) } }
                | { $0.all() }
        }
  
        return combine(branchName, upstreamName)
            | { pendingCommits(local: $0, remote: $1, direction: direction) }
    }
}

internal extension Repository {
    func pendingCommits(local: String, remote: String, direction: Direction) -> Result<[OID], Error> {
        switch direction {
        case .push:
            return walk(hideRef: remote, pushRef: local)
        case .fetch:
            return walk(hideRef: local, pushRef: remote)
        }
    }
    
    func walk(hideRef: String, pushRef: String) -> Result<[OID], Error> {
        Revwalk.new(in: self)
            | { $0.push(ref: pushRef) }
            | { $0.hide(ref: hideRef) }
            | { $0.all() }
    }
}

public class Revwalk : InstanceProtocol, ResultIterator {
    public typealias Success = OID
    
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    public static func new(in repo: Repository) -> R<Revwalk> {
        git_instance(of: Revwalk.self, "git_revwalk_new") { git_revwalk_new(&$0, repo.pointer) }
    }
    
    public func push(range: String) -> R<Revwalk> {
        git_try("git_revwalk_push_range") { git_revwalk_push_range(pointer, range) } | { self }
    }
    
    public func push(ref: String) -> R<Revwalk> {
        git_try("git_revwalk_push_ref") { git_revwalk_push_ref(pointer, ref) } | { self }
    }
    
    public func pushHead() -> R<Revwalk> {
        git_try("git_revwalk_push_head") { git_revwalk_push_head(pointer) } | { self }
    }
    
    public func hide(oid: OID) -> R<Revwalk> {
        var oid = oid.oid
        return git_try("git_revwalk_hide") { git_revwalk_hide(pointer, &oid) } | { self }
    }
    
    public func hide(ref: String) -> R<Revwalk> {
        git_try("git_revwalk_hide") { git_revwalk_hide_ref(pointer, ref) } | { self }
    }
    
    //        git_revwalk_sorting(pointer, GIT_SORT_TOPOLOGICAL.rawValue)
    //        git_revwalk_sorting(pointer, GIT_SORT_TIME.rawValue)
    //        git_revwalk_push(pointer, &oid)
    public func sorting(_ mode: UInt32) -> R<Revwalk> {
        git_try("git_revwalk_sorting") { git_revwalk_sorting(pointer, mode) } | { self }
    }
    
    // calls by all() in ResultIterator
    public func next() -> Result<OID?, Error> {
        var oid = git_oid()

        switch git_revwalk_next(&oid, pointer) {
        case GIT_ITEROVER.rawValue:
            return .success(nil)
        case GIT_OK.rawValue:
            return .success(OID(oid))
        default:
            return .failure(NSError(gitError: GIT_ERROR.rawValue, pointOfFailure: "git_revwalk_next"))
        }
    }
}
