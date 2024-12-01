
import Foundation
import Clibgit2
import Essentials

extension Diff.Delta : CustomStringConvertible {
    public var description: String {
        guard let oldFile else { return "Diff.Delta.oldFile == nil" }
        guard let newFile else { return "Diff.Delta.oldFile == nil" }
        
        let oids = oldFile.oid.oidShort + ":" + newFile.oid.oidShort + " "
        
        if self.status == .renamed {
            return "renamed:" + oids + oldFile.path + " -> " + newFile.path
        }
        
        if oldFile.path == newFile.path {
            return oids + oldFile.path
        } else {
            return oids + oldFile.path + " -> " + newFile.path
        }
    }
}
