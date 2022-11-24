
import Foundation
import Clibgit2

internal class Config: InstanceProtocol {
    public let pointer: OpaquePointer

    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }

    deinit {
        git_config_free(pointer)
    }
}

internal class ConfigIterator {
    var pointer : UnsafeMutablePointer<git_config_iterator>

    public required init(_ pointer: UnsafeMutablePointer<git_config_iterator>) {
        self.pointer = pointer
    }

    deinit {
        git_config_iterator_free(pointer)
    }
}

public struct ConfigEntry {
    public let level   : Level /**< Which config file this was found in */
    public let depth   : Int /**< Depth of includes where this variable was found */
    
    public let name    : String
    public let value   : String
    
    init?(_ entry: git_config_entry) {
        self.name = String(cString: entry.name)
        self.value = String(cString: entry.value)
        self.depth = Int(entry.include_depth)
        if let l = Level(rawValue: entry.level.rawValue) {
            self.level = l
        } else {
            return nil
        }
    }
    
    public enum Level : Int32 {
        case programdata = 1 // System-wide on Windows, for compatibility with portable git  GIT_CONFIG_LEVEL_PROGRAMDATA = 1,
        case system      = 2 // System-wide configuration file; /etc/gitconfig on Linux systems GIT_CONFIG_LEVEL_SYSTEM = 2,
        case xdg         = 3 // XDG compatible configuration file; typically ~/.config/git/config GIT_CONFIG_LEVEL_XDG = 3,
        case global      = 4 // User-specific configuration file (also called Global configuration file); typically ~/.gitconfig/ GIT_CONFIG_LEVEL_GLOBAL = 4,
        case local       = 5 // Repository specific configuration file; $WORK_DIR/.git/config on non-bare repos GIT_CONFIG_LEVEL_LOCAL = 5,
        case app         = 6 // Application specific configuration file; freely defined by applications     GIT_CONFIG_LEVEL_APP = 6,
        case highest     = -1 // Represents the highest level available config file (i.e. the most specific config file available that actually is loaded)     GIT_CONFIG_HIGHEST_LEVEL = -1,
    }
}

extension ConfigEntry.Level : CustomStringConvertible {
    public var description: String {
        switch self {
        case .programdata:  return  ".programdata"
        case .system:       return  ".system     "
        case .xdg:          return  ".xdg        "
        case .global:       return  ".global     "
        case .local:        return  ".local      "
        case .app:          return  ".app        "
        case .highest:      return  ".highest    "
        }
    }
}
