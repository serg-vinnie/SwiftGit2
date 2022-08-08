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
    
    public var isNone : Bool { if case .none = self { return true } else { return false } }
    
    public static func == (l: Credentials, r: Credentials) -> Bool {
        switch (l,r) {
        case     (.none, .none):                        return true
        case     (.default, .default):                  return true
        case     (.sshAgent, .sshAgent):                return true
        case let (.plaintext(l1,l2),.plaintext(r1,r2)): return l1 == r1 && l2 == r2
        case let (.sshMemory(l1,l2,l3,l4),.sshMemory(r1,r2,r3,r4)):
            return l1 == r1
                && l2 == r2
                && l3 == r3
                && l4 == r4
        case let (.ssh(l1,l2,l3), .ssh(r1,r2,r3)):
            return l1 == r1
                && l2 == r2
                && l3 == r3
        default:
            return false
        }
    }
}

public extension Credentials {
    static var sshDir : URL { URL.userHome.appendingPathComponent(".ssh") }
    
    private static var publicKey : URL { sshDir.appendingPathComponent("id_ed25519.pub") }
    private static var privateKey : URL { sshDir.appendingPathComponent("id_ed25519") }
    
    static var sshDefault: Credentials {
        guard publicKey.exists else { return .none }
        guard privateKey.exists else { return .none }

        return .ssh(publicKey: publicKey.path, privateKey: privateKey.path, passphrase: "")
    }
    
    static var sshAll: R<[Credentials]> {
//        let c1 = Credentials.ssh(publicKey: "/Users/loki/.ssh/id_rsa.pub", privateKey: "/Users/loki/.ssh/id_rsa", passphrase: "")
//        let c2 = Credentials.ssh(publicKey: "/Users/loki/.ssh/bla.pub", privateKey: "/Users/loki/.ssh/bla", passphrase: "")
//        return .success([c2, c1])
        
        let path = sshDir.path + "/"
        let files = sshDir.files
        let pubs  = files | { $0.filter { $0.hasSuffix(".pub") } }
        let maybePrivates = pubs | { $0.map { $0.replace(of: ".pub", to: "") } } | { Set($0) }
        
        return combine(files, maybePrivates)
            | { files, privs in files.filter { privs.contains($0) } }
            | { $0.map { .ssh(publicKey: path + $0 + ".pub", privateKey: path + $0, passphrase: "") } }
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
    
    public var descriptionShort: String {
        switch self {
        case .none:
            return "none"
        case .default:
            return "anonymous"
        case .sshAgent:
            return "sshAgent"
        case let .plaintext(username, password):
            return "name: \(username), password: \(password.asPassword))"
        case .sshMemory(username: let username, publicKey: _, privateKey: _, passphrase: _):
            return "sshMemory name: \(username) ...)"
        case let .ssh(publicKey, privateKey, _):
            return "publicKey: \(publicKey)\nprivateKey: \(privateKey)"
        }
    }
    
    public var asKeyName : String? {
        if case let .ssh(_, privateKey, _) = self {
            return URL(fileURLWithPath: privateKey).lastPathComponent
        }
        return nil
    }
}

private extension String {
    var asPassword : String {
        return String(self.map { _ in "*" })
    }
}
