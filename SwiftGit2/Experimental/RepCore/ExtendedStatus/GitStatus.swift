
import Foundation
import Essentials

fileprivate var _storage = LockedVar<[RepoID:StatusStorage]>([:])

public struct GitStatus {
    let repoID: RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitStatus {
    private var storage : StatusStorage {
        _storage.item(key: repoID) { StatusStorage(repoID: $0) }
    }
    
    var statusListDidChange : S<Void> { storage.statusListDidChange }
    
    func refreshing() -> R<ExtendedStatus> {
        storage.refreshing()
    }
    
    func refreshingSoft() -> R<ExtendedStatus> {
        storage.refreshingSoft()
    }
}

public extension ExtendedStatus {
    var stagingRatio : CGFloat {
        let state = status.map { $0.stageState }
        
        let staged = state.filter { $0 == .staged }
        let unstaged = state.filter { $0 == .unstaged }
        
        if staged.count == state.count {
            return 1
        }
        
        if unstaged.count == state.count {
            return 0
        }
        
        let weight = state.map { $0.weight }.reduce(0, +) / CGFloat(state.count)
        return clamp(weight, min: 0.1, max: 0.9)
    }
}

fileprivate func clamp<T: Comparable>(_ val: T, min: T, max: T) -> T {
    
    if val < min { return min }
    if val > max { return max }
    return val
}

extension StageState {
    var weight : CGFloat {
        switch self {
        case .staged: 1
        case .unstaged: 0
        case .mixed: 0.5
        case .unavailable: 0
        }
    }
}
