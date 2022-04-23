import Foundation
import Essentials
import Clibgit2

public struct GitRemotes {
    public let repoID : RepoID
    public init(repoID : RepoID) { self.repoID = repoID }
 
    public func add(url: String, name: String) -> R<Remote> {
        repoID.repo | { $0.createRemote(url: url, name: name) }
    }
}

// Remote
public extension Repository {
    func createRemote(url: String, name: String = "origin") -> Result<Remote, Error> {
        git_instance(of: Remote.self, "git_remote_create") { pointer in
            git_remote_create(&pointer, self.pointer, name, url)
        }
    }
    
    func getRemoteFirst() -> Result<Remote, Error> {
        return remoteNameList()
            .flatMap { arr -> Result<Remote, Error> in
                if let first = arr.first {
                    return self.remoteRepo(named: first)
                }
                return .failure(WTF("can't get RemotesNames"))
            }
    }
    
    func getAllRemotesCount() -> Result<Int, Error>{
        remoteNameList()
            .map{ $0.count }
    }
    
    func remoteList() -> Result<[Remote], Error> {
        return remoteNameList()
            .flatMap { $0.flatMap { self.remoteRepo(named: $0) } }
    }
    
    func remoteNameList() -> Result<[String], Error> {
        var strarray = git_strarray()
        
        return git_try("git_remote_list") {
            git_remote_list(&strarray, self.pointer)
        } | { strarray.map { $0 } }
    }
}
