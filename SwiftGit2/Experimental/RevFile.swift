//
//  RevFile.swift
//  AppCore
//
//  Created by UKS on 03.08.2021.
//  Copyright © 2021 Loki. All rights reserved.
//

import Foundation

class OidRevFile {
    private var content: String?
    
    public var contentAsOid: OID? {
        guard let content = content else { return nil }
        
        return OID(string: content)
    }
    
    private(set) var type: OidRevFileType
    
    private var gitDir: URL
    
    init? ( repo: Repository, type: OidRevFileType ) {
        guard let gitDir = (try? repo.gitDirUrl.get() )?.absoluteURL else { return nil }
        
        self.type = type
        self.gitDir = gitDir
        self.content = nil
        
        getContent(type: type)
    }
    
    private func getContent(type: OidRevFileType) {
        switch type {
        case .MergeHead:
            let url = gitDir.appendingPathComponent("MERGE_HEAD")
            guard exist(url) else { return }
            
            let f = FFile(r: url)
            
            content = f.readln()
            break
            
        default:
            break
        }
    }
    
    public func setOid(from commit: Commit?) -> OidRevFile {
        self.content = commit?.oid.description
        
        return self
    }
    
    func save() {
        switch type {
        case .MergeHead:
            if let content = content{
                let f = FFile(w: gitDir.appendingPathComponent("MERGE_HEAD").path )
                f.write(content)
            }
            
        default:
            break
        }
    }
}

class RevFile {
    private(set) var content: String?
    
    public var contentAsOid: OID? {
        guard let content = content else { return nil }
        
        return OID(string: content)
    }
    
    private(set) var type: RevFileType
    
    private var gitDir: URL
    
    init?( repo: Repository, type: RevFileType ) {
        guard let gitDir = (try? repo.gitDirUrl.get() )?.absoluteURL else { return nil }
        
        self.type = type
        self.gitDir = gitDir
        self.content = nil
        
        getContent(type: type)
    }
    
    private func getContent(type: RevFileType) {
        switch type {
        case .MergeMsg:
            let url = gitDir.appendingPathComponent("MERGE_MSG")
            guard exist(url) else { return }
            
            let f = FFile(r: url)
            
            var content = ""
            
            while let str = f.readln() {
                content += "\(str)\r\n"
            }
            
            self.content = content
            break
            
        default:
            break
        }
    }
    
    public func set(content: String) -> RevFile {
        self.content = content
        return self
    }
    
    func save() {
        switch type {
        case .MergeMsg:
            if let content = content{
                let f = FFile(w: gitDir.appendingPathComponent("MERGE_MSG").path )
                f.write(content)
            }
            
        default:
            break
        }
    }
}

enum RevFileType {
    case MergeMsg
    case SquashMsg //SQUASH_MSG
    case CommitEditMsg // COMMIT_EDITMSG
    //case MergeMode // MERGE_MODE
}
    
enum OidRevFileType {
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
