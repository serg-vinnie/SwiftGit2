
import Foundation
import Essentials


public struct ReferenceCache {
    public let referenceID: ReferenceID
    public let cache: GitRefCache
    
    init( _ ref: ReferenceID, cache: GitRefCache) {
        self.referenceID = ref
        self.cache  = cache
    }
}

public extension ReferenceCache {
    var isHead : Bool { self.cache.HEAD?.referenceID == self.referenceID }
}
