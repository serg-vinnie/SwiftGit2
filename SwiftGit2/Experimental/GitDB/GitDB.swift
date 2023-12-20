
import Foundation
import Essentials
import Clibgit2
import Parsing

public struct GitDB {
    let repoID: RepoID
    
    public init(repoID: RepoID) { self.repoID = repoID }
}


public extension GitDB {
    var objects : R<[GitDB.Object]> {
        return XR.Shell.Git(repoID: repoID).run(args: ["cat-file", "--batch-check", "--batch-all-objects", "--unordered"])
        | { $0.split(byCharsIn: "\n").compactMap { $0.asObject.maybeSuccess } }
    }
    
    var trees : R<[GitTree]> {
        objects | { $0.filter { $0.type == "tree" } } | { $0.map { GitTree(repoID: repoID, oid: $0.oid) } }
    }
}

fileprivate extension String {
    var asObject : R<GitDB.Object> {
        do {
            let (_oid, type, _) = try objectParser.parse(self)
            if let oid = OID(string: String(_oid)) {
                return .success(GitDB.Object(oid: oid, type: String(type)))
            } else {
                return .wtf("can't parse oid: \(_oid)")
            }
        } catch {
            return .failure(error)
        }
    }
}

var objectParser = Parse {
    Prefix { $0 != " " }
    " "
    Prefix { $0 != " " }
    Rest<String.SubSequence>()
}
