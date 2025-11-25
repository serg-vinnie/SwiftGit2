
import Clibgit2

public extension CheckoutStrategy {
    static var indexWithConflicts : CheckoutStrategy { [.Force, .AllowConflicts, .ConflictStyleMerge, .ConflictStyleDiff3] }
}

/// The flags defining how a checkout should be performed.
/// More detail is available in the libgit2 documentation for `git_checkout_strategy_t`.
public struct CheckoutStrategy: OptionSet {
    private let value: UInt

    // MARK: - Initialization

    /// Create an instance initialized with `nil`.
    public init(nilLiteral _: ()) {
        value = 0
    }

    public init(rawValue value: UInt) {
        self.value = value
    }

    public init(_ strategy: git_checkout_strategy_t) {
        value = UInt(strategy.rawValue)
    }

    public static var allZeros: CheckoutStrategy {
        return self.init(rawValue: 0)
    }

    // MARK: - Properties

    public var rawValue: UInt {
        return value
    }

    public var gitCheckoutStrategy: git_checkout_strategy_t {
        return git_checkout_strategy_t(UInt32(value))
    }

    // MARK: - Values

    /// Default is a dry run, no actual updates.
    nonisolated(unsafe) public static let None = CheckoutStrategy(GIT_CHECKOUT_NONE)

    /// Allow safe updates that cannot overwrite uncommitted data.
    nonisolated(unsafe) public static let Safe = CheckoutStrategy(GIT_CHECKOUT_SAFE)

    /// Allow all updates to force working directory to look like index
    nonisolated(unsafe) public static let Force = CheckoutStrategy(GIT_CHECKOUT_FORCE)

    /// Allow checkout to recreate missing files.
    nonisolated(unsafe) public static let RecreateMissing = CheckoutStrategy(GIT_CHECKOUT_RECREATE_MISSING)

    /// Allow checkout to make safe updates even if conflicts are found.
    nonisolated(unsafe) public static let AllowConflicts = CheckoutStrategy(GIT_CHECKOUT_ALLOW_CONFLICTS)

    /// Remove untracked files not in index (that are not ignored).
    nonisolated(unsafe) public static let RemoveUntracked = CheckoutStrategy(GIT_CHECKOUT_REMOVE_UNTRACKED)

    /// Remove ignored files not in index.
    nonisolated(unsafe) public static let RemoveIgnored = CheckoutStrategy(GIT_CHECKOUT_REMOVE_IGNORED)

    /// Only update existing files, don't create new ones.
    nonisolated(unsafe) public static let UpdateOnly = CheckoutStrategy(GIT_CHECKOUT_UPDATE_ONLY)

    /// Normally checkout updates index entries as it goes; this stops that.
    /// Implies `DontWriteIndex`.
    nonisolated(unsafe) public static let DontUpdateIndex = CheckoutStrategy(GIT_CHECKOUT_DONT_UPDATE_INDEX)

    /// Don't refresh index/config/etc before doing checkout
    nonisolated(unsafe) public static let NoRefresh = CheckoutStrategy(GIT_CHECKOUT_NO_REFRESH)

    /// Allow checkout to skip unmerged files
    nonisolated(unsafe) public static let SkipUnmerged = CheckoutStrategy(GIT_CHECKOUT_SKIP_UNMERGED)

    /// For unmerged files, checkout stage 2 from index
    nonisolated(unsafe) public static let UseOurs = CheckoutStrategy(GIT_CHECKOUT_USE_OURS)

    /// For unmerged files, checkout stage 3 from index
    nonisolated(unsafe) public static let UseTheirs = CheckoutStrategy(GIT_CHECKOUT_USE_THEIRS)

    /// Treat pathspec as simple list of exact match file paths
    nonisolated(unsafe) public static let DisablePathspecMatch = CheckoutStrategy(GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH)

    /// Ignore directories in use, they will be left empty
    nonisolated(unsafe) public static let SkipLockedDirectories = CheckoutStrategy(GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES)

    /// Don't overwrite ignored files that exist in the checkout target
    nonisolated(unsafe) public static let DontOverwriteIgnored = CheckoutStrategy(GIT_CHECKOUT_DONT_OVERWRITE_IGNORED)

    /// Write normal merge files for conflicts
    nonisolated(unsafe) public static let ConflictStyleMerge = CheckoutStrategy(GIT_CHECKOUT_CONFLICT_STYLE_MERGE)

    /// Include common ancestor data in diff3 format files for conflicts
    nonisolated(unsafe) public static let ConflictStyleDiff3 = CheckoutStrategy(GIT_CHECKOUT_CONFLICT_STYLE_DIFF3)

    /// Don't overwrite existing files or folders
    nonisolated(unsafe) public static let DontRemoveExisting = CheckoutStrategy(GIT_CHECKOUT_DONT_REMOVE_EXISTING)

    /// Normally checkout writes the index upon completion; this prevents that.
    nonisolated(unsafe) public static let DontWriteIndex = CheckoutStrategy(GIT_CHECKOUT_DONT_WRITE_INDEX)
}
