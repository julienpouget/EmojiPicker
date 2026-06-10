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
    /// intact — expand them manually. Both sides of a comparison must be
    /// folded with this same function (keywords are pre-folded at build time
    /// by `Scripts/generate-emoji-data.py`, whose `fold()` mirrors this).
    var searchFolded: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "æ", with: "ae")
    }
}
