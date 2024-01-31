
import Foundation
import Essentials

public enum MergeSource {
    case commit(CommitID)
    case reference(ReferenceID)
}

public struct GitMergeTree {
    public let src : MergeSource
    public let dst : ReferenceID
    
    public init(src: MergeSource, dst: ReferenceID) {
        self.src = src
        self.dst = dst
    }
}

public extension GitMergeTree {
    struct RowDuo : Identifiable {
        public let id = UUID() // compatibility with SwiftUI ForEach
        
        public let left  : Slot
        public let right : Slot
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

