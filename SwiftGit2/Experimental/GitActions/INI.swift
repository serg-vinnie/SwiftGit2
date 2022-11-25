
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
        public let name : Substring
        public let body : Substring
    }
}


var subParser = Parse {
    let quotedField = Parse {
      "\""
      Prefix { $0 != "\"" }
      "\""
    }
    
    return Parse {
        StartsWith("[submodule")
        Whitespace(.all)
        quotedField
        "]"
        Rest()
    }
}

public extension INI.Section {
    var submodule : R<INI.Submodule> {
        do {
            let (name,body) = try subParser.parse(text)
            return .success(INI.Submodule(name: name, body: body))
        } catch {
            return .failure(error)
        }
    }
    
    var isSubmodule : Bool {
        submodule.maybeSuccess != nil
    }
}

public extension INI.Parser {    
    var sections : R<[INI.Section]> {
        let endOfSection = OneOf {
            Prefix { $0 != "[" }
            Rest()
        }
        
        let section = Parse {
            StartsWith("[")
            endOfSection
        }
        
        let list = Many {
            section
        }
        
        do {
            var result = [Substring]()
            
            for item in try list.parse(text) {
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


struct IniFile {
    let url : URL
}




public extension XR {
    struct Parser {
        public let text : String
        public init(text: String) {
            self.text = text
        }
    }
}
