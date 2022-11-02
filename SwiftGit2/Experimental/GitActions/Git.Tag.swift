
import Foundation
import Essentials
import Clibgit2

public struct GitTag {
    public let repoID: RepoID
    
    public init(repoID: RepoID) {
        self.repoID = repoID
    }
}

public extension GitTag {
    func create(at oid: OID, name: String, message: String, signature: Signature) -> R<OID> {
        self.repoID.repo | { $0.createTag(from: oid, tag: name, message: message, signature: signature) }
    }
    
    internal var versions : R<[ReferenceID]> {
        
        return .notImplemented
    }
}

public extension Repository {
    /// Looks like works with advanced tags only
    func tagLookup(oid: OID) -> R<Tag> {
        var tagPointer: OpaquePointer? = nil
        var oidNeeded = oid.oid
        
        return git_try("git_tag_lookup_prefix") {
            git_tag_lookup_prefix(&tagPointer, self.pointer, &oidNeeded, 40);
        }
        .map {
            Tag(tagPointer!)
        }
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
        name = String(validatingUTF8: git_tag_name(pointer))!
        tagger = git_tag_tagger(pointer)?.pointee
        message = String(validatingUTF8: git_tag_message(pointer))!
    }
}
