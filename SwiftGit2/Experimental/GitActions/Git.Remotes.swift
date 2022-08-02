import Foundation
import Essentials
import Clibgit2
import OrderedCollections

public typealias GitRemotesList = OrderedDictionary<String,String>

public struct GitRemotes {
    public let repoID : RepoID
    public init(repoID : RepoID) { self.repoID = repoID }
}

public extension GitRemotes {
    func add(url: String, name: String) -> R<Remote> {
        repoID.repo | { $0.createRemote(url: url, name: name) }
    }
    
    func delete(name: String) -> R<Void> {
        repoID.repo | { $0.deleteRemote(name: name) }
    }
    
    func rename(old: String, new: String) -> R<Void> {
        repoID.repo | { $0.renameRemote(old: old, new: new) } | { _ in () }
    }
    
    func set(remote: String, url: String) -> R<Void> {
        repoID.repo | { $0.set(remote: remote, url: url) }
    }
    
    func remoteOf(reference: String) -> R<Remote> {
        guard reference.starts(with: "refs/remotes/") else {
            return .wtf("remoteOf(reference: should be remote")
        }
        if let remoteName = reference.replace(of: "refs/remotes/", to: "").split(separator: "/").first {
            return repoID.repo | { $0.remote(name: String(remoteName)) }
        }
        
        return .wtf("remoteOf(reference: IMPOSIBRU")
    }
    
    func fetch(name: String, options: @escaping (String)->FetchOptions) -> R<()> {
        repoID.repo | { $0.remote(name: name)
                    | { $0.fetch(options: options($0.url)) } }
                    | { _ in () }
    }
    
    var list        : R<GitRemotesList> { instances | { $0.toOrderedDictionary(key: \.name) { $0.url } } }
    var names       : R<[String]>       { repoID.repo | { $0.remoteNameList() } }
    var count       : R<Int>            { names | { $0.count } }
    
    var instances   : R<[Remote]>       { repoID.repo | { $0.remoteList()     } }
}

public extension GitRemotes {
    func fetchAll(options: @escaping (String)->FetchOptions) -> R<()> {
        (repoID.repo | { $0.remoteList() | { $0 | { $0.fetch(options: options($0.url)) } } } )
            .map { _ in () }
    }
}

extension Repository {
    func deleteRemote(name: String) -> R<()> {
        git_try("git_remote_delete") {
            git_remote_delete(self.pointer,name)
        }
    }
    
    func renameRemote(old: String, new: String) -> R<[String]> {
        var strarray = git_strarray()
        
        return git_try("git_remote_rename") {
            git_remote_rename(&strarray, self.pointer, old, new)
        } | { strarray.map { $0 } }
    }
    
    func set(remote: String, url: String) -> R<Void> {
        git_try("git_remote_set_url") {
            git_remote_set_url(self.pointer, remote, url)
        }
    }
}

// Remote
public extension Repository {
    func createRemote(url: String, name: String) -> Result<Remote, Error> {
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
