struct MergeHelperStrings {
    let c1_our = MergeFile(path: "Ifrit/Levenstain", name: "Levenstein.swift", content: main1)
    //new branch
    let c2_their = MergeFile(path: "Ifrit/Levenstein", name: "Levenstein.swift", content: their1)
}

struct MergeFile {
    let path: String
    let name: String
    let content: String
}


fileprivate let main1 = """
import Foundation

public class Levenstein {
    public static func searchSync(_ text: String, in aList: [String]) -> [FuzzySrchResult] {
        let tmp = aList.indices
            .map { idx -> FuzzySrchResult in
                let score = aList[idx].levenshteinDistanceScore(to: text, trimWhiteSpacesAndNewLines: true)
                
                return FuzzySrchResult(Int(idx), 1 - score, [])
            }
        
        return tmp
            .sorted(by: { $0.diffScore < $1.diffScore } )
    }
    
    public static func searchSync<T>(_ text: String,
                                     in aList: [T],
                                     by keyPath: KeyPath<T, [FuseProp]>) -> [FuzzySrchResult] where T: Searchable
    {
        let tmp = aList.enumerated()
            .compactMap { (idx, item) -> FuzzySrchResult?  in
                let allValues = item[keyPath: keyPath].map{ $0.value }
                
                if let score = searchSync(text, in: allValues).first?.diffScore {
                    return FuzzySrchResult(Int(idx), score, [] )
                }
                
                return nil
            }
        
        return tmp.sorted(by: { $0.diffScore < $1.diffScore } )
    }
    
    public static func searchFuzzy(_ text: String, 
                                   in aList: [String],
                                   match: Score = .defaultMatch,
                                   mismatch: Score = .defaultMismatch,
                                   gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
                                   boundaryBonus: Score = .defaultBoundary,
                                   camelCaseBonus: Score = .defaultCamelCase,
                                   firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
                                   consecutiveBonus: Score = Score.defaultConsecutiveBonus
    ) -> [Alignment] {
        return fuzzyFind(queries: [text], inputs: aList)
    }
    
    public static func searchFuzzy(_ searchQueries: [String],
                                   in aList: [String],
                                   match: Score = .defaultMatch,
                                   mismatch: Score = .defaultMismatch,
                                   gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
                                   boundaryBonus: Score = .defaultBoundary,
                                   camelCaseBonus: Score = .defaultCamelCase,
                                   firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
                                   consecutiveBonus: Score = Score.defaultConsecutiveBonus
    
    ) -> [Alignment] {
        return fuzzyFind(queries: searchQueries, inputs: aList)
    }
}

"""

let their1 = """
import Foundation

public enum LeventeinType {
    case bitap
    case text
}

public class Levenstein {
    public static func searchSync(type: LeventeinType = .text, _ text: String, in aList: [String]) -> [FuzzySrchResult] {
        switch type {
        case .bitap:
            LevensteinText.searchSync(text, in: aList)
        case .text:
            LevensteinBitap.searchSync(text, in: aList)
        }
    }
    
    public static func searchSync<T>(type: LeventeinType = .text,
                                     _ text: String,
                                     in aList: [T],
                                     by keyPath: KeyPath<T, [FuseProp]>) -> [FuzzySrchResult] where T: Searchable
    {
        switch type {
        case .bitap:
            LevensteinText.searchSync(text, in: aList, by: keyPath)
        case .text:
            LevensteinBitap.searchSync(text, in: aList, by: keyPath)
        }
    }
    
    public static func searchFuzzy(type: LeventeinType = .text,
                                   _ text: String,
                                   in aList: [String],
                                   match: Score = .defaultMatch,
                                   mismatch: Score = .defaultMismatch,
                                   gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
                                   boundaryBonus: Score = .defaultBoundary,
                                   camelCaseBonus: Score = .defaultCamelCase,
                                   firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
                                   consecutiveBonus: Score = Score.defaultConsecutiveBonus
    ) -> [Alignment] {
        switch type {
        case .bitap:
            fatalError()
            // not implemented
            return fuzzyFind(queries: [text], inputs: aList)
        case .text:
            return fuzzyFind(queries: [text], inputs: aList)
        }
    }
    
    public static func searchFuzzy(type: LeventeinType = .text,
                                   _ searchQueries: [String],
                                   in aList: [String],
                                   match: Score = .defaultMatch,
                                   mismatch: Score = .defaultMismatch,
                                   gapPenalty: (Int) -> Score = Score.defaultGapPenalty,
                                   boundaryBonus: Score = .defaultBoundary,
                                   camelCaseBonus: Score = .defaultCamelCase,
                                   firstCharBonusMultiplier: Int = Score.defaultFirstCharBonusMultiplier,
                                   consecutiveBonus: Score = Score.defaultConsecutiveBonus
    
    ) -> [Alignment] {
        switch type {
        case .bitap:
            fatalError()
            // not implemented
            return fuzzyFind(queries: searchQueries, inputs: aList)
        case .text:
            return fuzzyFind(queries: searchQueries, inputs: aList)
        }
    }
}

"""
