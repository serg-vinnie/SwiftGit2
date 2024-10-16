
import Clibgit2
import Foundation

public typealias CheckoutProgressBlock = (String?, Int, Int) -> Void

public class CheckoutOptions: GitPayload {
    private var checkout_options = git_checkout_options()
    fileprivate var checkoutProgressCB: CheckoutProgressBlock?
    
    private var pathspec: [String]

    public init(strategy: CheckoutStrategy = .Safe, pathspec: [String] = [], progress: CheckoutProgressBlock? = nil) {
        checkoutProgressCB = progress
        
        self.pathspec = pathspec
        
        git_checkout_options_init(&checkout_options, UInt32(GIT_CHECKOUT_OPTIONS_VERSION ))
        checkout_options.checkout_strategy = strategy.gitCheckoutStrategy.rawValue
        
        checkout_options.progress_payload = toRetainedPointer() // RETAIN
    }
    
    deinit {
        CheckoutOptions.release(pointer: checkout_options.progress_payload) // RELEASE
    }
}

extension CheckoutOptions {
    func with_git_checkout_options<T>(_ body: (inout git_checkout_options) -> T) -> T {
//        checkout_options.progress_payload = toRetainedPointer() // RETAIN
        checkout_options.progress_cb = checkoutProgressCallback
        
//        defer {
//            CheckoutOptions.release(pointer: checkout_options.progress_payload) // RELEASE
//        }
        
        if pathspec.isEmpty {
            return body(&checkout_options)
        } else {
            return pathspec.with_git_strarray { strarray in
                checkout_options.paths = strarray
                return body(&checkout_options)
            }
        }
    }
}

/// Helper function used as the libgit2 progress callback in git_checkout_options.
/// This is a function with a type signature of git_checkout_progress_cb.
private func checkoutProgressCallback(path: UnsafePointer<Int8>?, completedSteps: Int, totalSteps: Int, payload: UnsafeMutableRawPointer?) {
    guard let payload = payload else { return }
    guard let checkoutProgress = CheckoutOptions.unretained(pointer: payload).checkoutProgressCB else { return }
    
    checkoutProgress(path.flatMap(String.init(validatingUTF8:)), completedSteps, totalSteps)
}
