import Clibgit2
import Essentials
import Foundation

public enum PullPushResult {
    case conflict(Index)
    case success
}

public struct SyncOptions {
    public let pull: PullOptions
    public let push: PushOptions
    public init(pull: PullOptions, push: PushOptions) {
        self.pull = pull
        self.push = push
    }
}

public extension Repository {
    
    func sync(msg: String, options: SyncOptions, stashing: Bool) -> R<PullPushResult> {
        commit(message: msg, signature: options.pull.signature)
            .flatMap { _ in sync(.firstRemote, .HEAD, options: options, stashing: stashing)}
    }
    
    func sync(_ remoteTarget: RemoteTarget, _ branchTarget: BranchTarget, options: SyncOptions, stashing: Bool) -> R<PullPushResult> {
        return upstreamExistsFor(.HEAD)
            .if(\.self, then: { _ in
                pullAndPush(.HEAD, options: options, stashing: stashing)
            }, else: { _ in
                createUpstream(for: branchTarget, in: remoteTarget, options: options.push)
            })
    }
    
    func createUpstream(for branchTarget: BranchTarget, in remoteTarget: RemoteTarget, options: PushOptions) -> R<PullPushResult> {
        remoteTarget.with(self).createUpstream(for: branchTarget, force: true)
            | { _ in push(branchTarget, options: options) }
            | { .success }
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
