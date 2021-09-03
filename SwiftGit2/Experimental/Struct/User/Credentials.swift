//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

public enum Credentials {
    case none // always fail
    case `default`
    case sshAgent
    case plaintext(username: String, password: String)
    case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)
    case ssh(publicKey: String, privateKey: String, passphrase: String)
}

public extension Credentials {
    static var sshDir : URL { URL.userHome.appendingPathComponent(".ssh") }
    
    private static var publicKey : URL { sshDir.appendingPathComponent("id_rsa.pub") }
    private static var privateKey : URL { sshDir.appendingPathComponent("id_rsa") }
    
    static var sshDefault: Credentials {
        guard publicKey.exists else { return .none }
        guard privateKey.exists else { return .none }

        return .ssh(publicKey: publicKey.path, privateKey: privateKey.path, passphrase: "")
    }
    
    static var sshAll: R<[Credentials]> {
        let files = sshDir.files
        let pubs  = files | { $0.filter { $0.hasSuffix(".pub") } }
        let maybePrivates = pubs | { $0.map { $0.replace(of: ".pub", to: "") } } | { Set($0) }
        
        return combine(files, maybePrivates)
            | { files, privs in files.filter { privs.contains($0) } }
            | { $0.map { .ssh(publicKey: $0 + ".pub", privateKey: $0, passphrase: "") } }
    }

    func isSsh() -> Bool {
        switch self {
        case .ssh:
            return true
        default:
            return false
        }
    }
}

// Debug output with HIDDEN sensetive information
// example: Credentials.plaintext(username: example@gmail.com, password: ***************)
extension Credentials : CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "Credentials.none"
        case .default:
            return "Credentials.default"
        case .sshAgent:
            return "Credentials.sshAgent"
        case let .plaintext(username, password):
            return "Credentials.plaintext(username: \(username), password: \(password.asPassword))"
        case .sshMemory(username: let username, publicKey: _, privateKey: _, passphrase: _):
            return "Credentials.sshMemory(username: \(username) ...)"
        case let .ssh(publicKey, privateKey, passphrase):
            return "Credentials.ssh(publicKey: \(publicKey), privateKey: \(privateKey), passphrase: \(passphrase.asPassword)"
        }
    }
}

private extension String {
    var asPassword : String {
        return String(self.map { _ in "*" })
    }
}
