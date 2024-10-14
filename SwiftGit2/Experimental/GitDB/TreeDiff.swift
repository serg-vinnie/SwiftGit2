
import Foundation
import Essentials
import Clibgit2

public struct TreeDiffID : Hashable, Identifiable {
    public var id: String { (oldTree?.oid.description ?? "nil") + "_" + (newTree?.oid.description ?? "nil") }
    
    // both nils will return error
    let oldTree : TreeID?
    let newTree : TreeID?
}

public struct TreeDiff {
    public let deltas : [Diff.Delta]
    public let paths : [String:Diff.Delta.Status]
    public let folders : [String:[Diff.Delta.Status]]
    public let deletedPaths : [String:[String]]
    
    init(deltas: [Diff.Delta]) {
        self.deltas = deltas
    
        var _paths = [String:Diff.Delta.Status]()
        var _deletedPaths = [String:[String]]()
        var _folders = [String:[Diff.Delta.Status]]()
        
        for delta in deltas {
            if delta.status == .deleted, let path = delta.oldFile?.path {
                _deletedPaths.append(path.splitPathName)
                _paths[path] = delta.status
                for subPath in path.subPathes {
                    _folders.append(key: subPath, value: delta.status)
                }
                
            } else if delta.status == .renamed, let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                _paths[newPath] = delta.status
                _paths[oldPath] = delta.status
                _deletedPaths.append(oldPath.splitPathName)
                
                for subPath in newPath.subPathes {
                    _folders.append(key: subPath, value: delta.status)
                }
                
                for subPath in oldPath.subPathes {
                    _folders.append(key: subPath, value: delta.status)
                }
                
            } else if let path = delta.newFile?.path {
                _paths[path] = delta.status
                
                for subPath in path.subPathes {
                    _folders.append(key: subPath, value: delta.status)
                }
            }
        }
        
        self.paths = _paths
        self.deletedPaths = _deletedPaths
        self.folders = _folders
    }
}

extension TreeDiff : Hashable, Equatable {
    public static func == (lhs: TreeDiff, rhs: TreeDiff) -> Bool {
        lhs.paths == rhs.paths
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(paths)
    }
}


extension String {
    var splitPathName : (String, String) {
        var items = split(bySeparators: ["/"])
        if let name = items.popLast() {
            return (items.joined(separator: "/"), name)
        }
        return ("","")
    }
    
    var subPathes : [String] {
        var result = [String]()
        
        var accum = ""
        
        for item in split(bySeparators: ["/"]).dropLast() {
            if accum == "" {
                accum = item
            } else {
                accum += "/" + item
            }
            
            result.append(accum)
        }
        
        return result
    }
}

extension Dictionary where Key == String, Value == [String] {
    mutating func append(_ value: (String,String)) {
        guard !value.1.isEmpty else { return }
        
        if self.keys.contains(value.0) {
            self[value.0]?.append(value.1)
        } else {
            self[value.0] = [value.1]
        }
    }
}

extension Dictionary where Key == String, Value == [Diff.Delta.Status] {
    mutating func append(key: String, value: Diff.Delta.Status) {
        if self.keys.contains(key) {
            self[key]?.append(value)
        } else {
            self[key] = [value]
        }
    }
    
    func statuses(path: String) -> [Diff.Delta.Status] {
        self[path] ?? []
    }
}
