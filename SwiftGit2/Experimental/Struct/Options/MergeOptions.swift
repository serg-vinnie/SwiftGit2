//
//  MergeOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 12.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

public struct MergeOptions {
    var merge_options = git_merge_options()
    
    public init(mergeFlags: GitMergeFlag = [], fileFlags: GitMergeFileFlag = [], renameTheshold: Int = 50) {
        let result = git_merge_init_options(&merge_options, UInt32(GIT_MERGE_OPTIONS_VERSION))
        assert(result == GIT_OK.rawValue)
        
        merge_options.flags = mergeFlags.rawValue
        merge_options.file_flags = fileFlags.rawValue
        
        merge_options.rename_threshold = UInt32(renameTheshold)
    }
}

public struct GitMergeFlag: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public let rawValue: UInt32
    
    ///Detect renames that occur between the common ancestor and the "ours" side or the common ancestor and the "theirs" side. This will enable the ability to merge between a modified and renamed file.
    public static let findRenames    = GitMergeFlag(rawValue: GIT_MERGE_FIND_RENAMES.rawValue)
    
    ///If a conflict occurs, exit immediately instead of attempting to continue resolving conflicts. The merge operation will fail with GIT_EMERGECONFLICT and no index will be returned.
    public static let failOnConflict = GitMergeFlag(rawValue: GIT_MERGE_FAIL_ON_CONFLICT.rawValue)
    
    ///Do not write the REUC extension on the generated index
    public static let skipReuc       = GitMergeFlag(rawValue: GIT_MERGE_SKIP_REUC.rawValue)
    
    ///If the commits being merged have multiple merge bases, do not build a recursive merge base (by merging the multiple merge bases), instead simply use the first base. This flag provides a similar merge base to git-merge-resolve.
    public static let noRecurcive    = GitMergeFlag(rawValue: GIT_MERGE_NO_RECURSIVE.rawValue)
}

public struct GitMergeFileFlag: OptionSet {
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public let rawValue: UInt32
    
    public static let `default`                  = GitMergeFlag(rawValue: GIT_MERGE_FILE_DEFAULT.rawValue)
    
    ///Create standard conflicted merge files
    public static let styleMerge                 = GitMergeFlag(rawValue: GIT_MERGE_FILE_STYLE_MERGE.rawValue)
    
    ///Create diff3-style files
    public static let styleDiff3                 = GitMergeFlag(rawValue: GIT_MERGE_FILE_STYLE_DIFF3.rawValue)
    
    ///Condense non-alphanumeric regions for simplified diff file
    public static let simplifyAlnum              = GitMergeFlag(rawValue: GIT_MERGE_FILE_SIMPLIFY_ALNUM.rawValue)
    
    ///Ignore all whitespace
    public static let ignoreWhitespace           = GitMergeFlag(rawValue: GIT_MERGE_FILE_IGNORE_WHITESPACE.rawValue)
    
    ///Ignore changes in amount of whitespace
    public static let ignoreWhitespaceChagne     = GitMergeFlag(rawValue: GIT_MERGE_FILE_IGNORE_WHITESPACE_CHANGE.rawValue)
    
    ///Ignore  whitespace ind the end of lines
    public static let ignoreWhitespaceEndOfLines = GitMergeFlag(rawValue: GIT_MERGE_FILE_IGNORE_WHITESPACE_EOL.rawValue)
    
    ///Use the "patience diff" algorithm
    public static let diffPatience = GitMergeFlag(rawValue: GIT_MERGE_FILE_DIFF_PATIENCE.rawValue)
    
    ///Take extra time to find minimal diff
    public static let diffMinimal = GitMergeFlag(rawValue: GIT_MERGE_FILE_DIFF_MINIMAL.rawValue)
}
