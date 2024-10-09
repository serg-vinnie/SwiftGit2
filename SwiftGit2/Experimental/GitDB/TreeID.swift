
import Foundation
import Essentials
import Clibgit2

public struct TreeID : Hashable, Identifiable {
    public var id: OID { oid }
    
    public let repoID: RepoID
    public let oid: OID
    
    public init(repoID: RepoID, oid: OID) {
        self.repoID = repoID
        self.oid = oid
    }
}

public extension TreeID {
    internal var tree : R<Tree> { repoID.repo | { $0.treeLookup(oid: oid) } }
    
    var entries : R<[TreeID.Entry]> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.entries(repoID: repoID) } }
    }
    
    @available(macOS 12.0, *)
    var entriesSorted : R<[TreeID.Entry]> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.entries(repoID: repoID).sorted(using: TreeOrderCmp(order: .forward)) } }
    }
    
    func walk() -> R<()> {
        tree | { $0.walk() }
    }
    
    func extract(at: URL) -> R<()> {
        repoID.repo | { $0.treeLookup(oid: oid) | { $0.iteratorEntries(repoID: repoID, url: at) } }
                    | { $0 | { $0.extract() } } | { _ in ()}
    }
}


@available(macOS 12.0, *)
struct TreeOrderCmp : SortComparator {
    func compare(_ lhs: TreeID.Entry, _ rhs: TreeID.Entry) -> ComparisonResult {
        if lhs.kind != rhs.kind {
            if lhs.kind == .submodule { // submodule??
                return .orderedAscending
            }
            
            if rhs.kind == .submodule { // submodule??
                return .orderedDescending
            }
            
            if lhs.kind == .tree {
                return .orderedAscending
            }
            
            if rhs.kind == .tree {
                return .orderedDescending
            }
        } else {
            if lhs.name < rhs.name {
                return .orderedAscending
            }
            
            if lhs.name > rhs.name {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
    
    typealias Compared = TreeID.Entry
    
    var order: SortOrder
}
