
import Foundation
import Essentials
import Parsing

public struct INI {
    public struct Parser<T:StringProtocol> where T.SubSequence == Substring {
        public let text : T
        public init(_ text: T) { self.text = text }
    }
    
    public struct Section {
        public let text : Substring
        public init(_ text: Substring) { self.text = text }
    }
    
    public struct Submodule {
        public let text : Substring
        public let name : Substring
        public let body : Substring
    }
}

public extension INI.Section {
    var submodule : R<INI.Submodule> {
        do {
            let (name,body) = try submoduleParser.parse(text)
            return .success(INI.Submodule(text: text, name: name, body: body))
        } catch {
            return .failure(error)
        }
    }
    
    var isSubmodule : Bool {
        submodule.maybeSuccess != nil
    }
}

extension StringProtocol {
    func removing(submodule: INI.Submodule) -> String {
        var result = String(self)
        result.removeSubrange(submodule.text.startIndex..<submodule.text.endIndex)
        return result
    }
}

public extension INI.Parser {
    var submodules : R<[INI.Submodule]> {
        sections | { $0.filter { $0.isSubmodule } }
                 | { $0 | { $0.submodule } }
    }
    
    func deleting(submodule: String) -> R<String> {
        submodules | { $0.first { $0.name == submodule }.asNonOptional }
                   | { self.text.removing(submodule: $0) }
    }
    
    var sections : R<[INI.Section]> {
        do {
            var result = [Substring]()
            
            for item in try sectionsParser.parse(text) {
                let start = text.index(before: item.startIndex)
                let newsub : Substring = text[start..<item.endIndex]
                
                result.append(newsub)
            }
            
            return .success(result.map { INI.Section($0) })
        } catch {
            return .failure(error)
        }
    }
}

extension INI.Submodule : CustomStringConvertible {
    public var description: String { String(text) }
}

var submoduleParser = Parse {
    StartsWith("[submodule")
    Whitespace(.all)
    Parse {
        "\""
        Prefix { $0 != "\"" }
        "\""
    }
    "]"
    Rest()
}



var sectionsParser = Many {
    Parse {
        StartsWith("[")
        OneOf {
           Prefix { $0 != "[" }
           Rest()
       }
    }
}
