
import Foundation
import Essentials

enum MergeSource {
    case commit(CommitID)
    case reference(ReferenceID)
}

struct GitMergeTree {
    let src : MergeSource
    let dst : ReferenceID
}

extension GitMergeTree {
    struct RowDuo {
        let left  : Slot
        let right : Slot
    }
    
    enum Slot {
        case base(GitCommitBasicInfo)
        case commit(GitCommitBasicInfo)
        case branchFrom
        case mergeInto
        case empty
        case mergeTarget
    }
}

