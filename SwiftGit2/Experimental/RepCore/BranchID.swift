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
    public let referenceName: String
    
    public init (repoID: RepoID, ref: String) {
        self.repoID = repoID
        self.referenceName = ref
    }
}

public extension BranchID {
    var isLocal: Bool { referenceName.starts(with: "refs/heads") }
    var isRemote: Bool { referenceName.starts(with: "refs/remotes/") }
    
    var shortNameUnified: String {
        let partsToSkip = isLocal ? 2 : 3
        
        return referenceName.components(separatedBy: "/")
            .dropFirst(partsToSkip)
            .joined(separator: "/")
    }
}

//public extension BranchID {
//    public var reference : String { branch.nameAsReference }
//    public var localName: String { branch.nameAsReference }
//    public var type: BranchType { branch.checkBranchType() }
//    public var isHeadDetached: Bool { type == .detachedHead }
//
//    //'targetOID' is deprecated: prefered to use Duo<Reference,Repository> instead if possible
//    public var localCommitOid: OID? { try? branch.targetOID.get() }
//
//    public var shortNameUnified: String { branch.shortNameUnified }
//}

public extension Branch {
    func asBranchId(repoID: RepoID) -> BranchID {
        return BranchID(repoID: repoID, ref: self.nameAsReference)
    }
}


//public extension BranchID {
//    var isLocal: Bool { return type == .local || type == .localAndRemote }
//    var isLocalOnly: Bool { return type == .local }
//
//    var isRemote: Bool { return type == .remote || type == .localAndRemote }
//    var isRemoteOnly: Bool { return type == .remote }
//
//    var shortName: String {
//        if let rez = self.shortNameUnified.components(separatedBy: "/").last {
//            return rez
//        }
//        return shortNameUnified
//    }
//
//    var path: String {
//        let path = self.shortNameUnified
//            .components(separatedBy: "/")
//            .dropLast()
//            .joined(separator: "/")
//
//        return "\(path)/"
//    }
//
//    var isLocalAndRemoteNameDifferent: Bool {
//        if isHeadDetached { return false }
//
//        var local = localName.split(separator: "/")
//        var remote = upstreamName.split(separator: "/")
//
//        if (local.count > 0 && remote.count > 0){
//            local.removeSubrange(0...1)
//            let localPath = local.joined(separator: "/")
//
//            remote.removeSubrange(0...2)
//            let remotePath = remote.joined(separator: "/")
//
//            return localPath != remotePath
//        }
//
//        return false
//    }
//
//    var pathLocal: String { get{ return "refs/heads/" } }
//
//    var pathRemote: String {
//        let components = upstreamName.components(separatedBy: "/")
//
//        if components.count >= 2 {
//            let origin = components[2]
//            return "refs/remotes/\(origin)"
//        }
//
//        return ""
//    }
//}

public extension BranchID {
    func checkout(strategy: CheckoutStrategy = .Force, progress: CheckoutProgressBlock? = nil)  -> Result<Void, Error>  {
        let brId = self
        
        return self.repoID.repo
            .flatMap { repo in
                repo
                    .branchLookup(name: brId.referenceName)
                    .flatMap { branch in repo.checkout(branch: branch, strategy: strategy, progress: progress) }
            }
    }

////////////////////////
////////////////////////
// DO NOT CREATE SUCH METHODS! Its the reason of Bad Access Exception
    
//    func branch() -> R<Branch> {
//        self.repoID.repo
//            .flatMap { repo in
//                repo.branchLookup(name: referenceName)
//            }
//    }
    
//    func reference() -> R<Reference> {
//        self.repoID.repo
//            .flatMap { repo in
//                repo.reference(name: referenceName)
//            }
//    }
////////////////////////
////////////////////////
}

//////////////////////////////////////
// HELPERS
//////////////////////////////////////

extension BranchID: Identifiable {
    public var id: String {
        self.referenceName
    }
}
