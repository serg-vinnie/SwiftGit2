import Foundation
import Essentials

/////////////////////////////////
// NEW STATUS ENTRY
/////////////////////////////////


public extension StatusEntry {
    fileprivate func anyFilePath() -> Diff.File? {
        self.headToIndex?.oldFile ??
        self.indexToWorkDir?.oldFile ??
        self.headToIndex?.newFile ??
        self.indexToWorkDir?.newFile
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

