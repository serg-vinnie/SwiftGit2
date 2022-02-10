
import Essentials
import Foundation
@testable import SwiftGit2
import XCTest

struct GitTest {
    static let prefix = "git_test"
    static var localRoot = URL(fileURLWithPath: "/tmp/\(prefix)", isDirectory: true)
    static var tmpURL: Result<URL, Error> { URL.tmp(.systemUnique, prefix: GitTest.prefix) }
    static let signature = Signature(name: "XCode Unit Test", email: "email@domain.com")
    
    static let credentials_bullshit = Credentials.plaintext(username: "bullshit@gmail.com", password: "bullshit")
    static let credentials_01 = Credentials.plaintext(username: "xr.satan@gmail.com", password: "y2XvsUpdAw7PC28")
}

struct PublicTestRepo {
    let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!

    let localPath: URL
    let localPath2: URL

    init() {
        localPath = GitTest.localRoot.appendingPathComponent(urlSsh.lastPathComponent).deletingPathExtension()
        localPath2 = GitTest.localRoot.appendingPathComponent(localPath.lastPathComponent + "2")
        localPath.rm().shouldSucceed()
        localPath2.rm().shouldSucceed()
    }
}

extension String {    
    func write(to file: URL) -> Result<Void, Error> {
        do {
            try write(toFile: file.path, atomically: true, encoding: .utf8)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
