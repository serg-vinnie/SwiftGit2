
import Foundation
import Essentials

public struct GitFileLog {
    let file: GitFileID
    let prime : GitFileLogLine
    
    var files : [GitFileID] { prime.steps.flatMap { $0.files } }
}

public struct GitFileLogLine {
    let steps: [BranchStep]
    let splits : [GitLogSplit]
}

public struct GitLogSplit {
    let commitID : CommitID
    let parent : CommitID
    let parents : [CommitID]
}




extension GitFileID {
    public var log : R<GitFileLog> {
        logSector | { .init(file: self, prime: $0) }
    }
    
    var logSector : R<GitFileLogLine> {
        Result { try _logSector().expand() }
    }
    
    func _logSector() throws -> GitFileLogLine {
        guard let commitID else { throw WTF("commitID == nil at _logSector()") }
        let parents = try commitID.parents.get()
        
        guard let firstParent = parents.first else {
            let branchStep = BranchStep(start: self, next: [], isFinal: true, isComplete: true)
            return GitFileLogLine(steps: [branchStep], splits: [])
        }
        
        let branchStep = try self.branchStep(parentCommitID: firstParent)
        
        if parents.count == 1 {
            return GitFileLogLine(steps: [branchStep], splits: [])
        } else {
            let rest = Array(parents.dropFirst())
            let split = GitLogSplit(commitID: commitID, parent: firstParent, parents: rest)
            return GitFileLogLine(steps: [branchStep], splits: [split])
        }
    }
}

extension GitFileLogLine {
    var isFinal : Bool {
        guard let lastStep = self.steps.last else { return false }
        return lastStep.isFinal
    }
    
    func expand() throws -> GitFileLogLine {
        guard !isFinal else { return self }
        var step = try expandStep()
        while !step.isFinal {
            step = try step.expandStep()
        }
        return step
    }
    
    func expandStep() throws -> GitFileLogLine {
        guard let lastFile = self.steps.last?.files.last else { throw WTF("GitFileLogLine.expandStep() lastFile == nil") }
        guard let commitID = lastFile.commitID else { throw WTF("GitFileLogLine.expandStep() commitID == nil") }
        let parentsOfLastFile = try commitID.parents.get()
        
        guard let parent1_OfLastFile = parentsOfLastFile.first else {
            throw WTF("GitFileLogLine.expandStep() firstParent == nil") //return GitFileLogLine(steps: self.steps, splits: self.splits)
        }
        
        let parentsOfParent1 = try parent1_OfLastFile.parents.get()
        
        let diff = try lastFile.__diffToParent(commitID: parent1_OfLastFile).get()
        guard let delta = diff.asDeltas().first else {
            let nextFileID = GitFileID(path: lastFile.path, blobID: lastFile.blobID, commitID: parent1_OfLastFile)
            
            if let nextParent = parentsOfParent1.first {
                let nextStep = try nextFileID.branchStep(parentCommitID: nextParent)
                return .init(steps: self.steps + [nextStep], splits: self.splits)
            } else {
                throw WTF("GitFileLogSector.nextStep() NOT IMPLEMENTED")
            }
        }
        
        if delta.status == .modified {
            let treeID = try parent1_OfLastFile.treeID.get()
            let blobID = try treeID.blob(name: lastFile.path).get()
            let nextFileID = GitFileID(path: lastFile.path, blobID: blobID, commitID: parent1_OfLastFile)
//            let nextStep = try nextFileID.branchStep(parentCommitID: nextParent)
//            return .init(steps: self.steps + [nextStep], splits: self.splits)
            
            if let nextParent = parentsOfParent1.first {
                let nextStep = try nextFileID.branchStep(parentCommitID: nextParent)
                return .init(steps: self.steps + [nextStep], splits: self.splits)
            } else {
                throw WTF("GitFileLogSector.nextStep() NOT IMPLEMENTED")
            }
//            return BranchStep(start: self.start, next: self.next, isFinal: isFinal, isComplete: true)
//            throw WTF("GitFileLogSector.nextStep() NOT IMPLEMENTED: delta.status == .modified ")
        } else if delta.status == .added {
            throw WTF("GitFileLogSector.nextStep() NOT IMPLEMENTED: delta.status == .added ")
//            return BranchStep(start: self.start, next: self.next, isFinal: true, isComplete: true)
        }
        
        throw WTF("GitFileLogSector.nextStep() NOT IMPLEMENTED")
    }
}
