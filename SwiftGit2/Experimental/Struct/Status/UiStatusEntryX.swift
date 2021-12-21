import Foundation
import Essentials

/////////////////////////////////
// NEW STATUS ENTRY
/////////////////////////////////

public protocol UiStatusEntryX {
    var stageState: StageState { get }
    var stagedPatch: Result<Patch?, Error> { get }
    var unstagedPatch: Result<Patch?, Error> { get }
    
    ///indexToWorkDir
    var unStagedDeltas: Diff.Delta? { get }
    
    ///headToIndex
    var stagedDeltas: Diff.Delta? { get }
    var changesDeltas: Diff.Delta? { get }
    
    var oldFileRelPath: String? { get }
    var newFileRelPath: String? { get }
    
    var status: StatusEntry.Status { get }
    
    func statusFull() -> [Diff.Delta.Status]
    
    //var isBinary: Bool? { get }
}

public extension StatusEntry {
    func asStatusEntryX(repo: Repository) -> UiStatusEntryX {
        let entry = self
        
        var stagedPatch: R<Patch?>
        var unStagedPatch: R<Patch?>
        
        if let hti = entry.headToIndex {
            stagedPatch = repo.patchFrom(delta: hti)
                .map{ patch -> Patch? in patch }
        } else {
            stagedPatch = .success(nil)
        }
        
        if let itw =  entry.indexToWorkDir {
            unStagedPatch = repo.patchFrom(delta: itw)
                .map{ patch -> Patch? in patch }
        } else {
            unStagedPatch = .success(nil)
        }
        
        switch getChanged(repo: repo) {
        case let .success(changesDelta):
            return StatusEntryNew(entry, stagedPatch: stagedPatch, unStagedPatch: unStagedPatch, changesDeltas: changesDelta)
        case let .failure(error):
            print("StatusEntry.asStatusEntryX ERROR: \(error)")
            return StatusEntryNew(entry, stagedPatch: stagedPatch, unStagedPatch: unStagedPatch, changesDeltas: nil)
        }
    }
    
    fileprivate func getChanged(repo: Repository) -> R<[Diff.Delta]> {
        if let _ = repo.submoduleLookup(named: self.relPath).maybeSuccess {
            return .success([])
        }
        
        if self.statuses.contains(.added) || self.statuses.contains(.untracked) {
            return .success([])
        }
        
        // we don't need to detect renames in this case
        let headBlob = repo.deltas(target: .HEADorWorkDir, findOptions: Diff.FindOptions())
            .flatMap { $0.deltasWithHunks.fileOid(path: self.relPath) }
            .flatMap { repo.blob(oid: $0) }
        
        return combine(headBlob, repo.blobCreateFromWorkdirAsBlob(relPath: relPath))
            .flatMap { repo.diffBlobs(old: $0, new: $1) }
    }
    
    fileprivate func anyFilePath() -> Diff.File? {
        self.headToIndex?.oldFile ??
        self.indexToWorkDir?.oldFile ??
        self.headToIndex?.newFile ??
        self.indexToWorkDir?.newFile
    }
}

private struct StatusEntryNew: UiStatusEntryX {
    private var entry: StatusEntry
    private var stagedPatch_: Result<Patch?, Error>
    private var unStagedPatch_: Result<Patch?, Error>
    
    init(_ entry: StatusEntry, stagedPatch: Result<Patch?, Error>, unStagedPatch: Result<Patch?, Error>, changesDeltas: [Diff.Delta]?) {
        self.entry = entry
        self.stagedPatch_ = stagedPatch
        self.unStagedPatch_ = unStagedPatch
        self.changesDeltas = changesDeltas?.first
        //self.isBinary = isBinary
    }
    
    public var oldFileRelPath: String? { entry.headToIndex?.oldFile?.path ?? entry.indexToWorkDir?.oldFile?.path }
    
    public var newFileRelPath: String? { entry.headToIndex?.newFile?.path ?? entry.indexToWorkDir?.newFile?.path }
    
    public var stagedPatch: Result<Patch?, Error> { stagedPatch_ }
    
    public var unstagedPatch: Result<Patch?, Error> { unStagedPatch_ }
    
    var unStagedDeltas: Diff.Delta? { entry.indexToWorkDir }
    
    var stagedDeltas: Diff.Delta? { entry.headToIndex }
    
    var changesDeltas: Diff.Delta?
    
    var isBinary: Bool?
    
    var stageState: StageState {
        if entry.headToIndex != nil && entry.indexToWorkDir != nil {
            return .mixed
        }
        
        if let _ = entry.headToIndex {
            return .staged
        }
        
        if let _ = entry.indexToWorkDir {
            return .unstaged
        }
        
        assert(false)
        return .mixed
    }
    
    var status: StatusEntry.Status { entry.status }
    
    func statusFull() -> [Diff.Delta.Status] {
        if let status = unStagedDeltas?.status,
           stagedDeltas == nil {
                return [status]
        }
        if let status = stagedDeltas?.status,
            unStagedDeltas == nil {
                return [status]
        }
        
        guard let workDir = unStagedDeltas?.status else { return [.unmodified] }
        guard let index = stagedDeltas?.status else { return [.unmodified] }
        
        if workDir == index {
            return [workDir]
        }
        
        return [workDir, index]
    }
}


///////////////////////////////////
/// HELPERS
//////////////////////////////////
fileprivate extension StatusEntry{
    var relPath: String {
        self.headToIndex?.newFile?.path     ?? self.indexToWorkDir?.newFile?.path ??
            self.headToIndex?.oldFile?.path ?? self.indexToWorkDir?.oldFile?.path ?? ""
    }
}

private extension Array where Element == Diff.Delta {
    func fileOid(path: String) -> R<OID> {
        if let newFile = self.first(where: { $0.newFile?.path == path })?.newFile {
            return .success(newFile.oid)
        }
        
        return .wtf("can't find fileOid for path: \(path)")
    }
}

public extension UiStatusEntryX {
    var headToIndexNEWFilePath : R<String> {
        stagedDeltas.asNonOptional("headToIndex") | { $0.newFilePath }
    }
    
    var headToIndexOLDFilePath : R<String> {
        stagedDeltas.asNonOptional("headToIndex") | { $0.oldFilePath }
    }
    
    var indexToWorkDirNEWFilePath : R<String> {
        unStagedDeltas.asNonOptional("indexToWorkDir") | { $0.newFilePath }
    }
    
    var indexToWorkDirOLDFilePath : R<String> {
        unStagedDeltas.asNonOptional("indexToWorkDir") | { $0.newFilePath }
    }
}

public extension Duo where T1 == UiStatusEntryX, T2 == Repository {
    var headToIndexNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.headToIndexNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
    
    var indexToWorkDirNewFileURL : R<URL> {
        let (entry, repo) = self.value
        let path = entry.indexToWorkDirNEWFilePath
        return combine(repo.directoryURL, path) | { $0.appendingPathComponent($1) }
    }
}
