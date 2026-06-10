//
//  SearchFolding.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

extension String {
    /// The lowercased, diacritic-stripped form used for search comparisons,
    /// so "pinata" matches "piñata" and "cœur" matches "coeur".
    ///
    /// `œ`/`æ` are ligatures, not diacritics, so folding alone leaves them
    /// intact — expand them manually, and normalize curly apostrophes to the
    /// straight one people type. Both sides of a comparison must be folded
    /// with this same function (keywords are pre-folded at build time by
    /// `Scripts/generate-emoji-data.py`, whose `fold()` mirrors this).
    var searchFolded: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "\u{2019}", with: "'")
    }

    /// Word tokens of an already-folded string: split on anything that isn't
    /// a letter, a digit or `+`, dropping single characters unless they are
    /// digits. This mirrors the generator's tokenizer, so a query is cut the
    /// same way the stored keywords were ("j'adore" → ["adore"], "12:30" →
    /// ["12", "30"], "+1" stays whole).
    var searchTokens: [String] {
        split { !($0.isLetter || $0.isNumber || $0 == "+") }
            .map(String.init)
            .filter { $0.count > 1 || $0.first?.isNumber == true }
    }
}
