
import Foundation
import Essentials
import Clibgit2

public struct GitTag {
    public let repoID: RepoID
    
    public init(_ repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitTag {
    func createLight(at oid: OID, name: String, force: Bool = false) -> R<OID> {
        repoID.repo | { $0.createLightTag(at: oid, name: name, force: force) }
    }
    
    func create(at oid: OID, name: String, message: String, signature: Signature) -> R<OID> {
        repoID.repo | { $0.createTag(from: oid, tag: name, message: message, signature: signature) }
    }
    
    func delete(tag: String) -> R<Void> {
        repoID.repo | { $0.delete(tag: tag) }
    }
    
    func pushToRemote(tag: String, remote: String, auth: Auth, refspec: ReferenceID.PushRefspec) -> R<Void> {
        let repo = repoID.repo
        let refID = ReferenceID(repoID: repoID, name: "refs/tags/" + tag)
        
        let push = repo
        | { $0.remote(name: remote) }
        | { $0.push(refspec: refID.string(refspec: refspec), options: PushOptions(auth: auth)) }
        
        return push
    }
    
    func pushToFirstRemote(tag: String, auth: Auth) -> R<Void> {
        let repo = repoID.repo
        return (repo | { $0.remoteList() })
            .if(\.isEmpty,
                 then: { _ in .success(()) },
                 else: { list in list.first.asNonOptional
                     | { $0.push(refspec: ":refs/tags/\(tag)", options: PushOptions(auth: auth)) } }
            )
                .flatMapError { _ in .success(()) }
    }
    
    internal var versions : R<[ReferenceID]> {
        
        return .notImplemented
    }
}

public extension Repository {
    /// Looks like works with advanced tags only
    internal func tagLookup(oid: OID) -> R<Tag> {
        var tagPointer: OpaquePointer? = nil
        var oidNeeded = oid.oid
        
        return git_try("git_tag_lookup_prefix") {
            git_tag_lookup_prefix(&tagPointer, self.pointer, &oidNeeded, 40);
        }
        .map {
            Tag(tagPointer!)
        }
    }
    
    internal func delete(tag: String) -> R<Void> {
        git_try("git_tag_delete") {
            git_tag_delete(self.pointer, tag)
        }
    }
    
    func createLightTag(at commitOid: OID, name: String, force: Bool = false) -> R<OID> {
        var oid = git_oid()
        
        return self.commit(oid: commitOid) | { commit in
            git_try("git_tag_create") {
                git_tag_create_lightweight(&oid, self.pointer, name, commit.pointer, force ? 1 : 0)
            }
        } | { _ in OID(oid) }
    }
    
    fileprivate func createTag(from commitOid: OID, tag: String, message: String, signature: Signature) -> Result<OID, Error> {
        var oid = git_oid()
        
        return combine( signature.make(), self.commit(oid: commitOid) )
            .flatMap { signtr, commit in
                git_try("git_tag_create") {
                    git_tag_create(&oid, self.pointer, tag, commit.pointer, signtr.pointer, message, 0 )
                }
                .map { OID(oid) }
            }
    }
}

/// An annotated git tag.
public struct Tag: InstanceProtocol, ObjectType, Hashable  {
    public var pointer: OpaquePointer
    public static let type = GIT_OBJECT_TAG
    
    /// The OID of the tag.
    public let oid: OID
    
    /// The tagged object.
    //public let target: Pointer
    
    /// The tagged object.
    public var targetOid: OID
    
    /// The name of the tag.
    public let name: String
    
    /// The tagger (author) of the tag.
    public let tagger: git_signature?
    
    /// The message of the tag.
    public let message: String
    
    /// Create an instance with a libgit2 `git_tag`.
    public init(_ pointer: OpaquePointer) {
        self.pointer = pointer
        oid = OID(git_object_id(pointer).pointee)
        let targetOid = OID(git_tag_target_id(pointer).pointee)
        self.targetOid = targetOid
        //target = Pointer(oid: targetOid, type: git_tag_target_type(pointer))!
        name = git_tag_name(pointer).asSwiftString
        tagger = git_tag_tagger(pointer)?.pointee
        message = git_tag_message(pointer).asSwiftString
    }
}
