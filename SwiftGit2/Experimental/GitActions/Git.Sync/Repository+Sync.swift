import Clibgit2
import Essentials
import Foundation

public enum PullPushResult {
    case conflict(Index)
    case success
    case upstreamCreated(ReferenceID)
}

public struct SyncOptions {
    public let pull: PullOptions
    public let push: PushOptions
    public init(pull: PullOptions, push: PushOptions) {
        self.pull = pull
        self.push = push
    }
}

public extension ReferenceID {
    func createUpstream(in remoteTarget: RemoteTarget, pushOptions: PushOptions) -> R<PullPushResult> {
        let repo = self.repoID.repo
        let target = BranchTarget.branchShortName(self.displayName)
        
        return repo | { $0.createUpstream(for: target, in: remoteTarget, options: pushOptions)  }
    }
}

public extension Repository {
    
    func sync(_ remoteTarget: RemoteTarget, _ branchTarget: BranchTarget, options: SyncOptions, stashing: Bool) -> R<PullPushResult> {
        return upstreamExistsFor(.HEAD)
            .if(\.self, then: { _ in
                pullAndPush(.HEAD, options: options, stashing: stashing)
            }, else: { _ in
                createUpstream(for: branchTarget, in: remoteTarget, options: options.push)
            })
    }
    
    func createUpstream(for branchTarget: BranchTarget, in remoteTarget: RemoteTarget, options: PushOptions) -> R<PullPushResult> {
        let branch = remoteTarget.with(self).createUpstream(for: branchTarget, force: true)
        let push = push(branchTarget, options: options)
//        let repoID = push | { _ in self.repoID }
        
        return combine(self.repoID, branch, push)
            .map { repoID, branch, _ in ReferenceID(repoID: repoID, name: branch.nameAsReference) }
            .map { .upstreamCreated($0) }
    }
    
    func pullAndPush(_ target: BranchTarget, options: SyncOptions, stashing: Bool) -> R<PullPushResult> {
        switch pull(target, options: options.pull, stashing: stashing) {
        case let .success(result):
            switch result {
            case let .threeWayConflict(index):
                return .success(.conflict(index))
            default:
                return push(target, options: options.push)
                    .map { .success }
            }
        case let .failure(error):
            return .failure(error)
        }
    }
}
