
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
