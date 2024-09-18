
import Foundation
import SwiftUI
import Essentials

extension Result where Failure == Error {
    
    @discardableResult
    func failing(into pool: FSPool) -> Self {
        self.onFailure { error in pool.append(error: error) }
        return self
    }
}


@available(macOS 12.0, *)
public extension TreeID {
    class ViewModel : ObservableObject {
        let pool = FSPool(queue: .global(qos: .userInteractive))
        
        @Published var entries : [TreeID.Entry]
        @Published var navigation : TreeID.Navigation
        
        init(treeID: TreeID) {
            let entries = treeID.entriesSorted
            
            self.entries = entries.maybeSuccess ?? []
            self.navigation = Navigation(levels: [Level(treeID: treeID)])
        }
        
        func go(subTreeID: TreeID) {
            let nav = navigation.going(subTreeID: subTreeID)
            let entries = subTreeID.entriesSorted
            
            combine(nav, entries)
                .onSuccess { 
                    self.navigation = $0
                    self.entries = $1
                }
                .failing(into: pool)
        }
    }
}


