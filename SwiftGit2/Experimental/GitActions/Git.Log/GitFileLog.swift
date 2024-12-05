
import Foundation
import Essentials

public struct GitFileLog {
    let file: GitFileID
    let prime : GitFileLogSector
    
    var files : [GitFileID] { prime.steps.flatMap { $0.files } }
}

extension GitFileID {
    public var log : R<GitFileLog> {
        logSector | { .init(file: self, prime: $0) }
    }
    
    var logSector : R<GitFileLogSector> {
        Result { try _logSector() }
    }
    
    func _logSector() throws -> GitFileLogSector {
        guard let commitID else { throw WTF("commitID == nil at _logSector()") }
        let parents = try commitID.parents.get()
        
        guard let firstParent = parents.first else {
            let branchStep = BranchStep(start: self, next: [], isFinal: true, isComplete: true)
            return GitFileLogSector(steps: [branchStep], splits: [])
        }
        
        let branchStep = try self.branchStep(parentCommitID: firstParent)
        
        if parents.count == 1 {
            return GitFileLogSector(steps: [branchStep], splits: [])
        } else {
            let rest = Array(parents.dropFirst())
            let split = GitLogSplit(commitID: commitID, parent: firstParent, parents: rest)
            return GitFileLogSector(steps: [branchStep], splits: [split])
        }
    }
}


public struct GitFileLogSector {
    let steps: [BranchStep]
    let splits : [GitLogSplit]
}

public struct GitLogSplit {
    let commitID : CommitID
    let parent : CommitID
    let parents : [CommitID]
}
