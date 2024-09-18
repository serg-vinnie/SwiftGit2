
import Foundation
import Essentials

public extension TreeID {
    struct Level {
        let name: String
        let treeID: TreeID
        
        init(treeID: TreeID) {
            self.name = ""
            self.treeID = treeID
        }
        
        init(name: String, treeID: TreeID) {
            self.name = name
            self.treeID = treeID
        }
    }
    
    struct Navigation {
        let levels : [Level]
    }
}

extension TreeID.Navigation {
    func going(subTreeID: TreeID) -> R<TreeID.Navigation> {
        var newLevels = self.levels
        
        return .notImplemented
    }
}

extension Array {
    func element(idx: Int) -> R<Element> {
        guard self.count > idx else { return .wtf("[\(idx)] is out of bounds") }
        return .success(self[idx])
    }
}

public extension TreeID {
    func navigate(subTreeIdx idx: Int) -> R<Navigation> {
        entries
            | { $0.filter { $0.kind == .tree }.element(idx: idx) }
            | { TreeID(repoID: self.repoID, oid: $0.oid) }
            | { self.navigate(subTreeID: $0) }
    }
    
    func navigate(subTreeID: TreeID) -> R<Navigation> {
        let level1 = Level(treeID: self)
        let level2 = entries
            | { $0.first { $0.oid == subTreeID.oid }.asNonOptional("can't find by sub-TreeID \(subTreeID.oid)") }
            | { Level(name: $0.name, treeID: subTreeID) }
        
        return level2 | { Navigation(levels: [level1, $0]) }
    }
}
