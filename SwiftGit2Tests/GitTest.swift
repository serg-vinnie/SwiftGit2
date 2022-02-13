
import Essentials
import Foundation
@testable import SwiftGit2
import XCTest

struct GitTest {
    static let signature = Signature(name: "XCode Unit Test", email: "email@domain.com")
    
    static let credentials_bullshit = Credentials.plaintext(username: "bullshit@gmail.com", password: "bullshit")
    static let credentials_01 = Credentials.plaintext(username: "xr.satan@gmail.com", password: "y2XvsUpdAw7PC28")
}

struct PublicTestRepo {
    let urlSsh = URL(string: "git@gitlab.com:sergiy.vynnychenko/test_public.git")!
    let urlHttps = URL(string: "https://gitlab.com/sergiy.vynnychenko/test_public.git")!
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
