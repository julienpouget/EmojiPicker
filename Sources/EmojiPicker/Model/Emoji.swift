//
//  Emoji.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// A single emoji entry from the bundled Unicode dataset.
public struct Emoji: Identifiable, Hashable, Sendable {
    /// The default (yellow) presentation, e.g. `"👋"`. Also used as the stable identity.
    public let value: String

    /// The lowercase Unicode short name, e.g. `"waving hand"`.
    public let name: String

    /// The Emoji standard version that introduced this character, e.g. `14.0`.
    public let version: Double

    /// Search keyword tokens derived from the name and Unicode subgroup.
    public let keywords: [String]

    /// Uniform skin-tone variants, keyed by tone. Empty when unsupported.
    public let skinVariants: [EmojiSkinTone: String]

    /// The category this emoji belongs to in the dataset.
    public let category: EmojiCategory

    /// Pre-folded forms of the name and keywords (see `String.searchFolded`),
    /// computed once at init so per-keystroke matching stays a plain `contains`
    /// instead of an ICU-backed insensitive comparison per cell.
    let searchName: String
    let searchKeywords: [String]

    public var id: String { value }

    /// Whether this emoji can be rendered with a skin-tone modifier.
    public var supportsSkinTones: Bool { !skinVariants.isEmpty }

    public init(
        value: String,
        name: String,
        version: Double,
        keywords: [String],
        skinVariants: [EmojiSkinTone: String],
        category: EmojiCategory
    ) {
        self.value = value
        self.name = name
        self.version = version
        self.keywords = keywords
        self.skinVariants = skinVariants
        self.category = category
        self.searchName = name.searchFolded
        self.searchKeywords = keywords.map(\.searchFolded)
    }

    /// Returns the emoji string rendered with the given tone, falling back to
    /// the default presentation when the tone is `nil` or unsupported.
    public func string(for tone: EmojiSkinTone?) -> String {
        guard let tone, let variant = skinVariants[tone] else { return value }
        return variant
    }

    /// Returns `true` when `query` matches the name or keywords.
    ///
    /// `query` must already be search-folded (see `String.searchFolded`), which
    /// makes the match case- and diacritic-insensitive ("pinata" finds
    /// "piñata"). The whole query is first tried as a substring of the name, so
    /// natural phrases like `"red heart"` match directly. Otherwise every
    /// whitespace-separated token must match — as a name substring or a keyword
    /// prefix — so word order doesn't matter (`"up thumbs"` finds `"thumbs up"`).
    func matches(_ query: String) -> Bool {
        if searchName.contains(query) { return true }
        let tokens = query.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return false }
        return tokens.allSatisfy { token in
            searchName.contains(token) || searchKeywords.contains { $0.hasPrefix(token) }
        }
    }
}
