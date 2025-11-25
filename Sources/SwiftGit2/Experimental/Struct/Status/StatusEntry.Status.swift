import Foundation
import Clibgit2

public extension StatusEntry {
    struct Status: OptionSet {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        public let rawValue: UInt32
        
        nonisolated(unsafe) public static let current = Status(rawValue: GIT_STATUS_CURRENT.rawValue)
        nonisolated(unsafe) public static let indexNew = Status(rawValue: GIT_STATUS_INDEX_NEW.rawValue)
        nonisolated(unsafe) public static let indexModified = Status(rawValue: GIT_STATUS_INDEX_MODIFIED.rawValue)
        nonisolated(unsafe) public static let indexDeleted = Status(rawValue: GIT_STATUS_INDEX_DELETED.rawValue)
        nonisolated(unsafe) public static let indexRenamed = Status(rawValue: GIT_STATUS_INDEX_RENAMED.rawValue)
        nonisolated(unsafe) public static let indexTypeChange = Status(rawValue: GIT_STATUS_INDEX_TYPECHANGE.rawValue)
        nonisolated(unsafe) public static let workTreeNew = Status(rawValue: GIT_STATUS_WT_NEW.rawValue)
        nonisolated(unsafe) public static let workTreeModified = Status(rawValue: GIT_STATUS_WT_MODIFIED.rawValue)
        nonisolated(unsafe) public static let workTreeDeleted = Status(rawValue: GIT_STATUS_WT_DELETED.rawValue)
        nonisolated(unsafe) public static let workTreeTypeChange = Status(rawValue: GIT_STATUS_WT_TYPECHANGE.rawValue)
        nonisolated(unsafe) public static let workTreeRenamed = Status(rawValue: GIT_STATUS_WT_RENAMED.rawValue)
        nonisolated(unsafe) public static let workTreeUnreadable = Status(rawValue: GIT_STATUS_WT_UNREADABLE.rawValue)
        nonisolated(unsafe) public static let ignored = Status(rawValue: GIT_STATUS_IGNORED.rawValue)
        nonisolated(unsafe) public static let conflicted = Status(rawValue: GIT_STATUS_CONFLICTED.rawValue)
    }
}
