//
//  SshKeysReader.swift
//  TaoGit
//
//  Created by UKS on 29.09.2020.
//  Copyright © 2020 Cheka Zuja. All rights reserved.
//

import Foundation

@available(OSXApplicationExtension 10.12, *)
public class SshKeysManager {
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    // Needed to WRITE keys
    private(set) var urlPrivateKey: URL
    private(set) var urlPublicKey: URL
    
//    private(set) var keyPrivate: String = ""
//    private(set) var keyPublic: String = ""
    
    init() {
        urlPrivateKey = URL(fileURLWithPath: "\(home.path)/.ssh/id_rsa")
        urlPublicKey  = URL(fileURLWithPath: "\(home.path)/.ssh/id_rsa.pub")
        
        //keyPrivate = contentOf(url: urlPrivateKey)
        //keyPublic = contentOf(url: urlPublicKey)
    }
}

//@available(OSXApplicationExtension 10.15, *)
//extension SshKeysManager {
//    private func contentOf(url: URL) -> String{
//        var text: String = ""
//        let file = File.init(r: url)
//
//        while let str = file.readln() {
//            text += str
//        }
//
//        return text
//    }
//}
