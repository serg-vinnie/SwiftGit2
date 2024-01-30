
import Foundation
import Essentials

extension MergeSource {
    var repoID: RepoID {
        switch self {
        case let .commit(commitID): return commitID.repoID
        case let .reference(refID): return refID.repoID
        }
    }
    
    var oid : R<OID> {
        switch self {
        case let .commit(commitID): return .success(commitID.oid)
        case let .reference(refID): return refID.targetOID
        }
    }
}

extension GitMergeTree {
    var rows : R<[RowDuo]> {
        if src.repoID != dst.repoID { return .wtf("GitMergeTree: src and dst are from different repositories") }

        let ourOID      = dst.targetOID
        let theirOID    = src.oid
        let repo        = dst.repoID.repo
        let repoID      = dst.repoID
        
        let _combine = combine(repo,ourOID, theirOID)
        
        let baseOID = _combine | { $0.mergeBase(one: $1, two: $2) }
        let push = _combine | { repo, our, their in repo.oids(our: our, their: their) } | { $0.map { CommitID(repoID: repoID, oid: $0) } }
        let pull = _combine | { repo, our, their in repo.oids(our: their, their: our) } | { $0.map { CommitID(repoID: repoID, oid: $0) } }
        
        let base        = baseOID | { CommitID(repoID: repoID, oid: $0) } | { $0.basicInfo }
        let source      = push | { $0 | { $0.basicInfo } }
        let destination = pull | { $0 | { $0.basicInfo } }

        return combine(base, source, destination) | { combine(base: $0, source: $1, destination: $2) }
    }
}

fileprivate func combine(base: GitCommitBasicInfo, source: [GitCommitBasicInfo], destination: [GitCommitBasicInfo]) -> [GitMergeTree.RowDuo] {
    var _source      = [GitMergeTree.Slot]()
    var _destination = [GitMergeTree.Slot]()
    let _diffCount = source.count - destination.count
    
    _source.append(.mergeInto)
    _source.append(contentsOf: source.map { .commit($0) })
    
    _destination.append(.mergeTarget)
    _destination.append(contentsOf: destination.map { .commit($0) })
    
    if _diffCount > 0 { // source list larger
        _destination.append(contentsOf: Array(repeating: .empty, count: _diffCount))
    } else {
        _source.append(contentsOf: Array(repeating: .empty, count: abs(_diffCount)))
    }
    
    _source.append(.branchFrom)
    _destination.append(.base(base))
    
    assert(_source.count == _destination.count)
    
    return zip(_source,_destination).map { GitMergeTree.RowDuo(left: $0, right: $1) }
}
