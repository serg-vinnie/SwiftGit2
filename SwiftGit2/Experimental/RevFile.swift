//
//  RevFile.swift
//  AppCore
//
//  Created by UKS on 03.08.2021.
//  Copyright © 2021 Loki. All rights reserved.
//

import Foundation
import Essentials

public class OidRevFile {
    private var content: String?
    
    public var contentAsOid: OID? {
        guard let content = content else { return nil }
        
        return OID(string: content)
    }
    
    private(set) var type: OidRevFileType
    
    private var gitDir: URL
    
    public init? ( repo: Repository, type: OidRevFileType ) {
        guard let gitDir = (try? repo.gitDirUrl.get() )?.absoluteURL else { return nil }
        
        self.type = type
        self.gitDir = gitDir
        self.content = nil
        
        getContent(type: type)
    }
    
    private func getContent(type: OidRevFileType) {
        switch type {
        case .MergeHead:
            let file = File(url: gitDir.appendingPathComponent("MERGE_HEAD"))
            
            guard file.exists() else { return }
            
            content = file.getContent()
            
            break
            
        default:
            break
        }
    }
    
    public func setOid(from commit: Commit?) -> OidRevFile {
        self.content = commit?.oid.description
        
        return self
    }
    
    public func save() {
        switch type {
        case .MergeHead:
            if let content = content{
                try? File(url: gitDir.appendingPathComponent("MERGE_HEAD"))
                    .setContent(content)
            }
            
        default:
            print("Did you forgot to add something into save() method?")
            break
        }
        
        print("OidRevFile saved")
    }
}

public class RevFile {
    public private(set) var content: String?
    
    public var contentAsOid: OID? {
        guard let content = content else { return nil }
        
        return OID(string: content)
    }
    
    private(set) var type: RevFileType
    
    private var gitDir: URL
    
    public init?( repo: Repository, type: RevFileType ) {
        guard let gitDir = (try? repo.gitDirUrl.get() )?.absoluteURL else { return nil }
        
        self.type = type
        self.gitDir = gitDir
        self.content = File(url: gitDir.appendingPathComponent(type.asFileName())).getContent()
    }
    
    
    public func set(content: String) -> RevFile {
        self.content = content
        return self
    }
    
    func generatePullMsg(from index: Index) -> RevFile {
        return generateMergeMsgBase(from: index, msgHeader: "PULL conflicts resolve")
    }
    
    func generateMergeMsg(from index: Index, commit: Commit) -> RevFile {
        let msgHeader = "Merge commit '\(commit.oidShort)'"
        
        return generateMergeMsgBase(from: index, msgHeader: msgHeader )
    }
    
    private func generateMergeMsg(from index: Index, branchName: String) -> RevFile {
        let msgHeader = "Merge branch '\(branchName)'"
        
        return generateMergeMsgBase(from: index, msgHeader: msgHeader )
    }
    
    private func generateMergeMsgBase(from index: Index, msgHeader: String) -> RevFile {
        let separator = "\n * "
        
        let msgDescription = try? index
            .conflicts()
            .map { $0.map{ $0.description } }
            .map { files -> String in
                files.joined(separator: separator) }
            .map{ "Conflicts:\(separator)\($0)" }
            .get()
        
        if let msgDescription = msgDescription {
            self.content = "\(msgHeader)\n\n\(msgDescription)\n"
        }
        else {
            self.content = "\(msgHeader)"
        }
        
        return self
    }
    
    public func save()  -> RevFile {
        if let content = content {
            try? File(url: gitDir.appendingPathComponent( self.type.asFileName() ) )
                .setContent(content)
        }
        
        return self
    }
    
    public func delete() -> RevFile {
        File(url: gitDir.appendingPathComponent( self.type.asFileName() ) )
            .delete()
        
        return self
    }
}

public enum RevFileType: String {
    case MergeMsg
    case SquashMsg
    case CommitEditMsg
    //case MergeMode // MERGE_MODE
    
    //CUSTOMS
    case PullMsg // MERGE_MSG
    case CommitDescr
    
    func asFileName() -> String {
        switch self {
        case .PullMsg:
            fallthrough
        case .MergeMsg:
            return "MERGE_MSG"
        case .SquashMsg:
            return "SQUASH_MSG"
        case .CommitEditMsg:
            return "COMMIT_EDITMSG"
        case .CommitDescr:
            return "ZZ_TAO_CUSTOM_COMMIT_DESCR_MSG"
        }
    }
}
    
public enum OidRevFileType {
    case FetchHead
    case OrigHead
    case MergeHead
    case CherryPickHead //CHERRY_PICK_HEAD
    case BisectHead //BISECT_HEAD
    case RevertHead //REVERT_HEAD
    case RejectNonFfHead //REJECT_NON_FF_HEAD
}


fileprivate func exist(_ url: URL) -> Bool {
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: url.path)
}
