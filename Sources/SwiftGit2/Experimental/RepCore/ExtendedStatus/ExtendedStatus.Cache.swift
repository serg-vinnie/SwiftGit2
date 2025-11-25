
import Foundation
import Clibgit2
import Essentials

public extension ExtendedStatus {
    class Cache {
        public var uuid  = LockedVar<UUID>(UUID())
        public var hunks = LockedVar<[Int:StatusEntryHunks]>([:])
        
        //public var hunks_ = LockedVar<[String:StatusEntryHunks]>([:])
        public var signature = ExtendedStatus.Signature(entries: [])
        
        public init() {}
        
        public func verify(uuid: UUID) {
            let _uuid = self.uuid.read { $0 }
            if uuid == _uuid {
                return
            }
            self.uuid.access { $0 = uuid }
            self.hunks.access { $0.removeAll() }
        }
    }
}
