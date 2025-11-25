
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
    public let paths : [String:Diff.Delta.StatusEx]
    public let folders : [String:[Diff.Delta.StatusEx]]
    public let deletedPaths : [String:[String]]
    
    init(deltas: [Diff.Delta]) {
        self.deltas = deltas
    
        var _paths = [String:Diff.Delta.StatusEx]()
        var _deletedPaths = [String:[String]]()
        var _folders = [String:[Diff.Delta.StatusEx]]()
        
        for delta in deltas {
            if delta.status == .deleted, let path = delta.oldFile?.path {
                _deletedPaths.append(path.splitPathName)
                _paths[path] = delta.status.asEx
                for subPath in path.subPathes {
                    _folders.append(key: subPath, value: delta.status.asEx)
                }
                
            } else if delta.status == .renamed, let oldPath = delta.oldFile?.path, let newPath = delta.newFile?.path {
                _paths[newPath] = .renamedAdded
                _paths[oldPath] = .renamedDeleted
                _deletedPaths.append(oldPath.splitPathName)
                
                let newSP = newPath.subPathes
                let oldSP = oldPath.subPathes
                
                let count = countCommonPrefixElements(array1: newSP, array2: oldSP)
                let commonPrefix = newSP.prefix(count)
                let newSP_suffix = newSP.dropFirst(count)
                let oldSP_suffix = oldSP.dropFirst(count)
                
                
                for subPath in commonPrefix {
                    _folders.append(key: subPath, value: delta.status.asEx)
                }
                for subPath in newSP_suffix {
                    _folders.append(key: subPath, value: .renamedAdded)
                }
                for subPath in oldSP_suffix {
                    _folders.append(key: subPath, value: .renamedDeleted)
                }
                
            } else if let path = delta.newFile?.path {
                _paths[path] = delta.status.asEx
                
                for subPath in path.subPathes {
                    _folders.append(key: subPath, value: delta.status.asEx)
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

extension Dictionary where Key == String, Value == [Diff.Delta.StatusEx] {
    mutating func append(key: String, value: Diff.Delta.StatusEx) {
        if self.keys.contains(key) {
            self[key]?.append(value)
        } else {
            self[key] = [value]
        }
    }
    
    func statuses(path: String) -> [Diff.Delta.StatusEx] {
        self[path] ?? []
    }
}

func countCommonPrefixElements<T: Equatable>(array1: [T], array2: [T]) -> Int {
    var count = 0
    let minLength = min(array1.count, array2.count)
    
    for i in 0..<minLength {
        if array1[i] == array2[i] {
            count += 1
        } else {
            break
        }
    }
    
    return count
}
