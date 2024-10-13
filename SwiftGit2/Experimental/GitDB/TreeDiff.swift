
import Foundation
import Essentials
import Clibgit2

public struct TreeDiffID : Hashable, Identifiable {
    public var id: String { (oldTree?.oid.description ?? "nil") + "_" + (newTree?.oid.description ?? "nil") }
    
    // both nils will return error
    let oldTree : TreeID?
    let newTree : TreeID?
}

public struct TreeDiff {
    public let deltas : [Diff.Delta]
    public let paths : [String:Diff.Delta.Status]
    public let deletedPaths : [String:String]
    
    init(deltas: [Diff.Delta]) {
        self.deltas = deltas
    
        var _paths = [String:Diff.Delta.Status]()
        var _deletedPaths = [String:String]()
        
        for delta in deltas {
            if delta.status == .deleted {
                
            } else if delta.status == .renamed {
                
            } else if let path = delta.newFile?.path {
                _paths[path] = delta.status
            }
        }
        
        self.paths = _paths
        self.deletedPaths = _deletedPaths
    }
}

extension TreeDiff : Hashable, Equatable {
    public static func == (lhs: TreeDiff, rhs: TreeDiff) -> Bool {
        lhs.paths == rhs.paths
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(paths)
    }
}
