
import Foundation
import Essentials

public extension RepoID {
    struct Tree<Agent: TreeAgent> {
        public private(set) var items         = Swift.Set<Agent>()
        public private(set) var childrenOf    = [Agent:Swift.Set<Agent>]()
        public private(set) var allChildrenOf = [Agent:Swift.Set<Agent>]()
        public private(set) var parentOf      = [Agent:Agent]()
        public private(set) var parentsOf     = [Agent:[Agent]]()
    }
}

extension RepoID.Tree {
    mutating func add( _ agent: Agent) {
        let children = agent.treeChildren
        add(children: children, parent: agent)
        allChildrenOf[agent] = Set(agent.treeAllChildren)
        for ch in children {
            add(ch)
        }
    }
    
    mutating func add(children: [Agent], parent: Agent) {
        self.items.insert(parent)
        
        guard children.isEmpty else { return }
        
        let parents = [parent] + (parentsOf[parent] ?? [])
        childrenOf[parent] = Set(children)
        
        for item in children {
            parentOf[item] = parent
            parentsOf[item] = parents
        }
    }
}

public protocol TreeAgent : Hashable {
    var treeChildren : [Self] { get }
    var treeAllChildren : [Self] { get }
}

extension RepoID : TreeAgent {
    public var treeChildren: [RepoID] {
        (module | { $0.subModules.values.compactMap { $0?.repoID } })
            .maybeSuccess ?? []
    }
    
    public var treeAllChildren: [RepoID] {
        (module | { $0.subModulesRecursive.values.compactMap { $0?.repoID } })
            .maybeSuccess ?? []
    }
}
