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
    
    public var contentAsOids: [OID] {
        guard let oidStrs = content?.split(separator: "\n") else { return [] }
        
        return oidStrs
                .map{ OID(string: "\($0)" ) }
                .compactMap{ $0 }
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
    
    public func delete() -> OidRevFile {
        File(url: gitDir.appendingPathComponent( self.type.asFileName() ) )
            .delete()
        
        return self
    }
    
    public func exist() -> Bool {
        File(url: gitDir.appendingPathComponent(type.asFileName())).exists()
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
        try? File(url: gitDir.appendingPathComponent( self.type.asFileName() ) )
            .setContent(content ?? "")
        
        return self
    }
    
    public func delete() -> RevFile {
        File(url: gitDir.appendingPathComponent( self.type.asFileName() ) )
            .delete()
        
        return self
    }
    
    public func exist() -> Bool {
        File(url: gitDir.appendingPathComponent(type.asFileName())).exists()
    }
}


public enum RevFileType: String {
    case MergeMsg
    case SquashMsg
    case CommitEditMsg
    case MergeMode
    
    //CUSTOMS
    case PullMsg // MERGE_MSG
    case CommitDescr
    
    func asFileName() -> String {
        switch self {
        case .PullMsg:
            fallthrough
        case .MergeMsg:
            return "MERGE_MSG"
        case .MergeMode:
            return "MERGE_MODE"
        case .SquashMsg:
            return "SQUASH_MSG"
        case .CommitEditMsg:
            return "COMMIT_EDITMSG"
        case .CommitDescr:
            return "COMMIT_DESCRIPTION_TAO_GIT"
        }
    }
}
    
public enum OidRevFileType {
//    case FetchHead
    case OrigHead
    case MergeHead
    case CherryPickHead
    case BisectHead
    case RevertHead
    case RejectNonFfHead
    
    func asFileName() -> String {
        switch self {
//        case .FetchHead:
//            return ""
        case .OrigHead:
            return "ORIG_HEAD"
        case .MergeHead:
            return "MERGE_HEAD"
        case .CherryPickHead:
            return "CHERRY_PICK_HEAD"
        case .BisectHead:
            return "BISECT_HEAD"
        case .RevertHead:
            return "REVERT_HEAD"
        case .RejectNonFfHead:
            return "REJECT_NON_FF_HEAD"
        }
    }
}


fileprivate func exist(_ url: URL) -> Bool {
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: url.path)
}

public extension Optional where Wrapped == OidRevFile {
    func exist() -> Bool {
        self?.exist() ?? false
    }
}

public extension Optional where Wrapped == RevFile {
    func exist() -> Bool {
        self?.exist() ?? false
    }
}

//FETCH_HEAD - зберігає в собі запис з іменем бранча з останнього виклику git fetch. (вводиться вручну при виклику git_remote_fetch в параметр reflog_message )
//ORIG_HEAD - створюється командами які різко змінюють HEAD на інший. Він створюється для того що б можна було відкотити назад дію якщо щось піде не так.
//MERGE_HEAD - записується коміт який ти намагаєшся підмерджити в твій хеад. Наприклад 851e89d0445bfc885fb16d9cf090bd1276fc787e
//MERGE_MODE - ?
//MERGE_MSG - повідомлення що видається як дескріпшн мерджа (лонг меседж). Лібгітом не створюється автоматично. Гітом створюється через якийсь відповідний хук - https://git-scm.com/docs/githooks
//CHERRY_PICK_HEAD - записує запис з іменем бранча останнього виклику git cherry-pick. Наприклад 851e89d0445bfc885fb16d9cf090bd1276fc787e
//SQUASH_MSG - ?
//BISECT_HEAD - ?
//REVERT_HEAD - ?
//REJECT_NON_FF_HEAD - ?
//(повного такого єдиного списку не існує в документації. Тож треба по крихтам вичіпляти з різних кутків документації)
//
//(краще файли зберігати в UTF-8)
//Всього в лібгіті лише 2 команди мають можливість створювати рефлог файл подібний з ручним вказуванням меседжа -git_remote_fetch та
//git_remote_update_tips
//
//Можливо може бути корисною інформація про хуки до цієї теми - але тавер використовує явно не їх. Бо всі хуки що тавер генерить по-факту являються семплами і не виконуються на практиці.
