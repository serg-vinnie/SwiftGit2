import Foundation
import Essentials

public extension XR.Shell {
    struct Git {
        let workDir : URL
        
        public init(at workDir : URL) {
            self.workDir = workDir
        }
        
        public init(repoID: RepoID) {
            self.workDir = repoID.url
        }
        
//        public func run(args: [String]?) -> R<String> {
//            let binPath = Bundle.main.path(forAuxiliaryExecutable: "git") ?? "/usr/bin/git"
////            guard  else {
////                return .failure(WTF("can't resolve Auxiliary Executable git"))
////            }
//            
//            let shell = XR.Shell(cmd: binPath, workDir: workDir)
//            
//            return shell.run(args: args, waitUntilExit: false).outputAsString
//        }
        public func run(args: [String]?) -> R<String> {
            let binPath = Bundle.main.path(forAuxiliaryExecutable: "git") ?? "/usr/bin/git"
//            guard  else {
//                return .failure(WTF("can't resolve Auxiliary Executable git"))
//            }
            
            let shell = XR.Shell(cmd: binPath, workDir: workDir)
            
            return shell.run3(args: args)
        }
        
        public func add(path: String) -> R<String> {
            return run(args: ["add", path])
        }
        
        public func reset(path: String) -> R<String> {
            return run(args: ["reset", path])
        }
        
        public func commit(msg: String, author: String) -> R<String> {
            return run(args: ["commit", "-m", msg, "--author=\"\(author)\""])
        }
    }
}

//Written by UKS
extension XR.Shell.Git {
    public func resetBranchTo(oid: String, type: ResetBranchType) -> R<String> {
        return run( args: ["reset", type.rawValue , oid] )
    }
    
    public func patchFrom(commit: Commit, pathToLocatePatch: String) -> R<String> {
        //git format-patch -1 (short or full Oid) -o \(dirToLocatePatch)
        // -1 - means "generate single patch for all of files of the commit
        // -o - means output folder
        return run( args: ["format-patch", "-1" , commit.oidShort, "-o", pathToLocatePatch] )
    }
    
    public func applyPatch(patchPath: String) -> R<String> {
        //git am \(pathOfPatch)
        
        //with skipping errors:
        //git am --skip \(pathOfPatch)
        
        var terminalCommand = ["apply"]
        
        terminalCommand.append(patchPath)
        
        let rez = run( args: terminalCommand )
        
        rez.onFailure{ print("ZZZ1: \($0.localizedDescription )") }
        rez.onSuccess{ print("ZZZ2: \($0)") }
        
        return rez
    }
    
//    public func createTag(oid: String, tag: String, message: String? = nil) -> R<String> {
//        let args: [String]
//
//        if let message = message {
//            //git tag -a someTag 86a1370 -m "message"
//            args = ["tag","-a",tag, oid , "-m" , message]
//        } else {
//            //git tag someTag 86a1370
//            args = ["tag", tag, oid]
//        }
//
//        return run(args: args)
//    }
}

////////////////////////////
///HELPERS
////////////////////////////
public enum ResetBranchType: String {
    case hard = "--hard"
    case soft = "--soft"
    case mixed = "--mixed"
}

extension Process.TerminationReason : CustomStringConvertible {
    public var description: String {
        switch self {
        case .exit:
            return "exit"
        case .uncaughtSignal:
            return "uncaughtSignal"
        @unknown default:
            return "@unknown default"
        }
    }
}
