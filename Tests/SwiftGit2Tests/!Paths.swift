
import Foundation

// Need to remove this struct and generate repos for tests locally
struct Paths {
    static var taoGitUrl: URL {
        switch ProcessInfo.processInfo.userName {
        case "uks":
            return URL(fileURLWithPath: "/Users/uks/TaoGitRepos/taogit")
        case "loki":
            return URL.userHome.appendingPathComponent("dev/taogit")
        default:
            return URL.userHome.appendingPathComponent("dev/taogit")
        }
    }
    
    static var focusitoUrl: URL {
        return URL(string: "git@gitlab.com:UKS/focusito_2.git")!
    }
}
