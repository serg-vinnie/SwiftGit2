//
//  BranchID.swift
//  SwiftGit2Tests
//
//  Created by UKS on 05.05.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials

public struct BranchID {
    public let repoID : RepoID
    public let upstreamName: String
    
    private let branch: Branch
    
    public var reference : String { branch.nameAsReference }
    public var localName: String { branch.nameAsReference }
    public var type: BranchType { branch.checkBranchType() }
    public var isHeadDetached: Bool { type == .detachedHead }
    
    //'targetOID' is deprecated: prefered to use Duo<Reference,Repository> instead if possible
    public var localCommitOid: OID? { try? branch.targetOID.get() }
    
    public var shortNameUnified: String { branch.shortNameUnified }

    
    public init(repoID: RepoID, local branch: Branch, upstreamName: String = "") {
        self.repoID = repoID
        self.branch = branch
        self.upstreamName = upstreamName
    }
    
    public init(repoID: RepoID, remote branch: Branch) {
        self.repoID = repoID
        self.branch = branch
        self.upstreamName = branch.nameAsReference
    }
}

public extension Branch {
    func asBranchId(repoID: RepoID) -> BranchID {
        return BranchID(repoID: repoID, local: self)
    }
    
    var shortNameUnified: String {
        if let name = nameAsBranch {
            if name.contains("/"){
                return name.split(separator: "/")
                    .dropFirst()
                    .joined(separator: "/")
            }
            
            return name
        } else {
            let newName = nameAsReference
                .split(separator: "/")
                .dropFirst(2)
                .joined(separator: "/")
            
            return newName
        }
    }
    
    func checkBranchType() -> BranchID.BranchType {
        var isRemote = self.isRemote
        let isLocal = self.isBranch
        
        // TODO: Hack
        // and this hack works only on local branches
        if isLocal && !isRemote {
            if let _ = self.upstreamName().maybeSuccess {
                isRemote = true
            }
        }
        
        if isLocal && isRemote {
            return .localAndRemote
        } else if isLocal {
            return .local
        }
        
        return .remote
    }
}

public extension BranchID {
    enum BranchType: Comparable  {
        case local
        case remote
        case localAndRemote
        case detachedHead
        
        private var sortOrder: Int {
            switch self {
                case .detachedHead:
                    return 0
                case .localAndRemote:
                    return 1
                case .local:
                    return 2
                case .remote:
                    return 3
            }
        }
        
        public static func ==(lhs: BranchType, rhs: BranchType) -> Bool {
            return lhs.sortOrder == rhs.sortOrder
        }
        
        public static func <(lhs: BranchType, rhs: BranchType) -> Bool {
           return lhs.sortOrder < rhs.sortOrder
        }
    }
}

public extension BranchID {
    var isLocal: Bool { return type == .local || type == .localAndRemote }
    var isLocalOnly: Bool { return type == .local }
    
    var isRemote: Bool { return type == .remote || type == .localAndRemote }
    var isRemoteOnly: Bool { return type == .remote }
    
    var shortName: String {
        if let rez = self.shortNameUnified.components(separatedBy: "/").last {
            return rez
        }
        return shortNameUnified
    }
    
    var path: String {
        let path = self.shortNameUnified
            .components(separatedBy: "/")
            .dropLast()
            .joined(separator: "/")
        
        return "\(path)/"
    }
    
    var isLocalAndRemoteNameDifferent: Bool {
        if isHeadDetached { return false }
        
        var local = localName.split(separator: "/")
        var remote = upstreamName.split(separator: "/")
        
        if (local.count > 0 && remote.count > 0){
            local.removeSubrange(0...1)
            let localPath = local.joined(separator: "/")
            
            remote.removeSubrange(0...2)
            let remotePath = remote.joined(separator: "/")
            
            return localPath != remotePath
        }
        
        return false
    }
    
    var pathLocal: String { get{ return "refs/heads/" } }
    
    var pathRemote: String {
        let components = upstreamName.components(separatedBy: "/")
        
        if components.count >= 2 {
            let origin = components[2]
            return "refs/remotes/\(origin)"
        }
        
        return ""
    }
}

public extension BranchID {
    func checkout(strategy: CheckoutStrategy = .Force, progress: CheckoutProgressBlock? = nil)  -> Result<Void, Error>  {
        let brId = self
        
        return self.repoID.repo
            .flatMap { repo in
                repo
                    .branchLookup(name: brId.localName)
                    .flatMap { branch in repo.checkout(branch: branch, strategy: strategy, progress: progress) }
            }
    }
}
