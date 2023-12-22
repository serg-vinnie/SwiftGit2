
import Foundation
import Essentials
import Clibgit2
import Parsing

public struct GitDB {
    let repoID: RepoID
    
    public init(repoID: RepoID) { self.repoID = repoID }
}


public extension GitDB {    
    var entries : R<[String]> {
        XR.Shell.Git(repoID: repoID)
            .run(args: ["cat-file", "--batch-check", "--batch-all-objects", "--unordered"])
            //.map { $0.split(byCharsIn: "\n") }
    }
    
    var trees : R<[TreeID]> {
        entries | { $0.compactMap { $0.asTreeID(repoID: self.repoID).maybeSuccess } }
    }
}

private extension String {
    func asTreeID(repoID: RepoID) -> R<TreeID> {
        do {
            let (_oid, type, _) = try objectParser.parse(self)
            if type == "tree" {
                if let oid = OID(string: String(_oid)) {
                    return .success(TreeID(repoID: repoID, oid: oid))
                } else {
                    return .wtf("can't parse oid: \(_oid)")
                }
            } else {
               return .wtf("not a tree")
            }
        } catch {
            return .failure(error)
        }
    }
}

fileprivate var objectParser = Parse {
    Prefix { $0 != " " }
    " "
    Prefix { $0 != " " }
    Rest<String.SubSequence>()
}
