//
//  ReferenceID.swift
//  SwiftGit2-OSX
//
//  Created by loki on 26.07.2022.
//  Copyright © 2022 GitHub, Inc. All rights reserved.
//

import Foundation
import Essentials
import Clibgit2

public struct ReferenceID : Equatable, Hashable, Comparable {
    public let repoID: RepoID
    public let name: String
    
    public init(repoID: RepoID, name: String) {
        self.repoID = repoID
        self.name = name
    }
    
    public static func < (lhs: ReferenceID, rhs: ReferenceID) -> Bool {
        if lhs.name == "HEAD" { return true }
        if rhs.name == "HEAD" { return false }
        
        if lhs.displayName == "HEAD" { return true }
        if rhs.displayName == "HEAD" { return false }
        
        
        return lhs.name < rhs.name
    }
}

public extension ReferenceID {
    var isBranch  : Bool { name.hasPrefix("refs/heads/") }
    var isRemote  : Bool { name.hasPrefix("refs/remotes/") }
    var isTag     : Bool { name.hasPrefix("refs/tags/") }
    
    var exists    : Bool { self.reference.maybeSuccess != nil }
    
    var prefix      : String {
        if name.starts(with: "refs/heads/") { return "refs/heads/" }
        if let remote = remote, name.starts(with: "refs/remotes/") { return "refs/heads/\(remote)/" }
        if name.starts(with: "refs/tags/") { return "refs/tags/" }
        
        return ""
    }
    var prefixEx      : String {
        if name.starts(with: "refs/heads/")     { return "refs/heads/" }
        if name.starts(with: "refs/remotes/")   { return "refs/heads/" }
        if name.starts(with: "refs/tags/")      { return "refs/tags/" }
        
        return ""
        
    }
    
    var displayName : String {
        if isBranch {
            return name.replace(of: "refs/heads/", to: "")
        } else if let remote = remote {
            return name.replace(of: "refs/remotes/\(remote)/", to: "")
        } else if isTag {
            return name.replace(of: "refs/tags/", to: "")
        }
        
        return name
    }
    
    var displayNameEx : String {
        if isBranch {
            return name.replace(of: "refs/heads/", to: "")
        } else if isRemote {
            return name.replace(of: "refs/remotes/", to: "")
        } else if isTag {
            return name.replace(of: "refs/tags/", to: "")
        }

        return name
    }
    
    var category : String {
        let parts = name.split(separator: "/")
        guard parts.count > 1 else { return "" }
        return String(parts[1])
    }
    
    var remote : String? {
        let parts = name.split(separator: "/")
        if parts.count > 3 {
            if parts[1] == "remotes" {
                return String(parts[2])
            }
        }
        
        return nil
    }
    
    private var reference : R<Reference> { repoID.repo | { $0.reference(name: name) } }
    
    var isSymbolic : R<Bool> { reference | { $0.isSymbolic } }
    var isDirect : R<Bool> { reference | { $0.isDirect } }
    var symbolic : R<ReferenceID> { reference | { $0.nameAsReferenceSymbolic.asNonOptional } | { ReferenceID(repoID: repoID, name: $0) } }
    
    var targetOID : R<OID> {
        if self.isTag {
            return repoID.repo | { r in r.reference(name: name) | { $0.with(r).getTagOid() }}
        } else {
            return repoID.repo | { r in r.reference(name: name) | { $0.with(r).targetOID() }}
        }
    }
    
    enum TagType {
        case lightweight(OID)
        case annotated(Tag)
    }
    
    var tagType : R<TagType> {
        guard isTag else { return .wtf("not a tag") }
        
        let repo = repoID.repo
        let oid = repo | { $0.reference(name: name) } | { $0.target }
        let tag = combine(repo, oid) | { $0.tagLookup(oid: $1) }
        
        return tag.map { .annotated($0) }
            .flatMapError { _ in oid | { .lightweight($0) } }
    }
    
    /*
     
     // Getting oid for Advanced or LightWeight tag
     func getTagOid() -> R<OID> {
         let repo = value.1
         
         return self.targetOID()
             .flatMap { oid -> R<OID> in
                 if repo.commitExists(oid: oid) {
                     // this is lightWeight Tag
                     return .success(oid)
                 } else {
                     // this is Advanced Tag
                     return repo.tagLookup(oid: oid).map{ $0.targetOid }
                 }
             }
     }
     */
    
    /*
     
     func targetOID() -> R<OID> {
         let (ref, repo) = value
         
         if ref.isSymbolic {
             return ref.nameAsReferenceSymbolic.asNonOptional | { repo.referenceTarget(name: $0) }
         } else {
             return ref.targetOIDNoWarning
         }
     }

     */
    
    var annotatedCommit : R<AnnotatedCommit> {
        combine(repoID.repo, targetOID) | { repo, oid in repo.annotatedCommit(oid: oid) }
    }
}

public enum ReferenceType {
    case local
    case remote
    case tag
}

public extension RepoID {
    
    var references : R<[ReferenceID]> {
        repo | { $0.references } | { $0.map { ReferenceID(repoID: self, name: $0) } }
    }

    func references(_ location: ReferenceType) -> R<[ReferenceID]> {
        switch location {
        case .local:
            return self.references | { $0.filter { $0.name.starts(with: "refs/heads/") } }

        case .remote:
            return self.references | { $0.filter { $0.name.starts(with: "refs/remotes/") } }

        case .tag:
            return self.references | { $0.filter { $0.name.starts(with: "refs/tags/") } }
        }
    }
}



public extension ReferenceID {
    var isLocalBr: Bool { name.starts(with: "refs/heads") }
    var isRemoteBr: Bool { name.starts(with: "refs/remotes/") }

    var shortNameUnified: String {
        let partsToSkip = isLocalBr ? 2 : 3

        return name.components(separatedBy: "/")
            .dropFirst(partsToSkip)
            .joined(separator: "/")
    }
}

public extension Branch {
    func asReferenceID(repoID: RepoID) -> ReferenceID {
        return ReferenceID(repoID: repoID, name: self.nameAsReference)
    }
}


public extension ReferenceID {
    func checkout(options: CheckoutOptions, stashing: Bool)  -> Result<Void, Error>  {
        repoID.repo | { repo in
            GitStasher(repo: repo).wrap(skip: !stashing) {
                repo.setHEAD(self.name) | { repo.checkoutHead(options: options) }
            }
        }
    }
    func checkout(options: CheckoutOptions)  -> Result<Void, Error>  {
        repoID.repo | { repo in
            repo.setHEAD(self.name) | { repo.checkoutHead(options: options) }
        }
    }
}

extension ReferenceID: Identifiable {
    public var id: String {
        self.name
    }
}

extension Repository {
    func referenceNameToId(name: String) -> R<OID> {
        var oid = git_oid() // out
        
        return git_try("git_reference_name_to_id") {
                name.withCString { name in
                    git_reference_name_to_id(&oid, self.pointer, name)
                }
            }
            .map {
                OID(oid)
            }
    }
}
