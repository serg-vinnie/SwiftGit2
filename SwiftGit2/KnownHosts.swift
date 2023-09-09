import Foundation
import Essentials

fileprivate var sshDir: URL { URL.userHome.appendingPathComponent(".ssh") }

public class KnownHosts {
    static func get() -> R<[HFHost]> {
        let urlToOpen = sshDir.appendingPathComponent("known_hosts")
        
        if !urlToOpen.exists {
            return .failure(WTF("\"known_hosts\" file does not exist"))
        }
        
        guard let content = File(url: urlToOpen).getContent() else { return .failure( WTF("Failed to get content of \"known_hosts\" file") ) }
        
        return getFromText(content)
    }
    
    static func getFromText(_ content: String ) -> R<[HFHost]> {
        let fileContent = content.removingUselessSpaces()
        
        let strings = fileContent.split(separator: "\n").map{ $0.split(separator: " ").map{ "\($0)" } }
        
        for str in strings {
            if str.count != 3 {
                return .failure( WTF("Incorrect format of \"known_hosts\" file. Try to recreate file") )
            }
        }
        
        let result = strings.map { row in
            let hosts = row[0].split(separator: ",").map{ "\($0)"}
            let sshType = row[1]
            let key = row[2]
            
            return HFHost(hosts: hosts, sshType: sshType, key: key)
        }
        
        return .success(result)
    }
}

public struct HFHost: Equatable {
    var hosts: [String]
    var sshType: String
    var key: String
}

fileprivate extension String {
    func removingUselessSpaces() -> String {
        // remove incorrect whitespaces
        var result1 = self.filter { $0 == " " || ($0.isNewline || !$0.isWhitespace) }
        
        var result2 = ""
        
        for char in result1 {
            if char == " " && result2.last == " " {
                //do nothing
            } else {
                result2.append(char)
            }
        }
        
        return result2
    }
}
