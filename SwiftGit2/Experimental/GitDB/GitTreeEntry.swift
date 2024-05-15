
import Foundation
import Essentials

enum GitTreeEntry {
    case file(GitFileID)
    case tree(TreeID)
    case submodule(SubmoduleID)
}

//extension TreeID {
//    var entries : R<[GitTreeEntry]> {
//        
//    }
//}
