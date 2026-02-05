
import Clibgit2
import Essentials

public extension Repository {
    func HEAD() -> R<Reference> {
        git_instance(of: Reference.self, "git_repository_head") { p in
            git_repository_head(&p, self.pointer)
        }
    }

    var headIsUnborn: Bool { git_repository_head_unborn(pointer) == 1 }
    var headIsDetached: Bool { git_repository_head_detached(pointer) == 1 }
    
    func commitsFromHead(num: Int) -> R<[Commit]> {
        self.commitsIn(range: "HEAD~\(num)..HEAD")
            .flatMapError{_ in self.commitsFromHead() }
    }
    
    func commitsIn(range: String) -> R<[Commit]> {
        let oids = Revwalk.new(in: self) | { $0.push(range: range) } | { $0.all() }
        return oids.flatMap { $0.flatMap { self.commit(oid: $0) } }
    }
    
    func commitsFromHead() -> R<[Commit]> {
        let oids = Revwalk.new(in: self) | { $0.pushHead() } | { $0.all() }
        return oids.flatMap { $0.flatMap { self.commit(oid: $0) } }
    }
}

public enum DetachedHeadFix {
    case notNecessary
    case fixed
    case ambiguous(branches: [ReferenceID])
}

public extension RepoID {
    var masterRefID : ReferenceID { .init(repoID: self, name: "refs/heads/master") }
    var mainRefID   : ReferenceID { .init(repoID: self, name: "refs/heads/main") }
    
    func fixIfHeadIsUnborn() -> R<Void> {
        repo | { $0.fixIfHeadIsUnborn() }
    }
}

private extension Array where Element == ReferenceID {
    func checkoutFirstExisting() -> R<Void> {
        for refID in self {
            if refID.exists {
                return refID.checkout(options: CheckoutOptions())
            }
        }
        return .success(())
    }
}

public extension Repository {
    func fixIfHeadIsUnborn() -> R<Void> {
        if headIsUnborn {
            let mainRefID = self.repoID | { $0.mainRefID }
            let masterRefID = self.repoID | { $0.mainRefID }
            let refs = self.repoID | { GitReference($0).list(.local) }
            return combine(mainRefID, masterRefID, refs) | { main, master, list in [main, master] + list } | { $0.checkoutFirstExisting() }
        }
        
        return .success(())
    }
    
    func detachedHeadFix() -> Result<DetachedHeadFix, Error> {
        guard headIsDetached else {
            return .success(.notNecessary)
        }
        
        let headOID = HEAD().flatMap{ Duo($0, self).targetOID() }
        
        let br_infos = branches(.local)
            .flatMap { $0.flatMap { Branch_Info.create(from: $0) } }

        return combine(br_infos, headOID)
            .map { br_infos, headOid in br_infos.filter { $0.oid == headOid } }
            .map { $0.map { $0.branch.nameAsReference } }
            .if({ $0.count == 1 },
                then: { $0.checkoutFirst(in: self).map { _ in DetachedHeadFix.fixed } },
                else: { list in
                        self.repoID | { repoID in
                            .ambiguous(branches: list.map { ReferenceID(repoID: repoID, name: $0) })
                        }
                      }
            )
    }

    // possible solution
    // not in use yet
    private func resolveAmbiguity(branches: [String]) -> Result<DetachedHeadFix, Error> {
        // if there are two branches
        // then checkout NOT master
        guard branches.count == 2,
              let masterIdx = branches.masterIdx else {
            return self.repoID | { repoID in
                    .ambiguous(branches: branches.map { ReferenceID(repoID: repoID, name: $0) } )
            }
        }

        if masterIdx == 0 {
            return checkout(ref: branches[1], stashing: false).map { .fixed }
        } else {
            return checkout(ref: branches[0], stashing: false).map { .fixed }
        }
    }
}

private extension Array where Element == String {
    var masterIdx: Int? {
        firstIndex(of: "refs/heads/master")
    }

    func checkoutFirst(in repo: Repository) -> Result<Void, Error> {
        first.asResult { repo.checkout(ref: $0, stashing: false) }
    }
}

private struct Branch_Info {
    let branch: Branch
    let oid: OID

    static func create(from branch: Branch) -> Result<Branch_Info, Error> {
        branch.target_result
            .map { Branch_Info(branch: branch, oid: $0) }
    }
}

extension DetachedHeadFix: Equatable {
    public static func == (lhs: DetachedHeadFix, rhs: DetachedHeadFix) -> Bool {
        switch (lhs, rhs) {
        case (.fixed, .fixed): return true
        case (.notNecessary, .notNecessary): return true
        case let (.ambiguous(a_l), .ambiguous(a_r)):
            return a_l == a_r
        default: return false
        }
    }
}
