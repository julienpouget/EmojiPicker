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
    }

    /// Returns the emoji string rendered with the given tone, falling back to
    /// the default presentation when the tone is `nil` or unsupported.
    public func string(for tone: EmojiSkinTone?) -> String {
        guard let tone, let variant = skinVariants[tone] else { return value }
        return variant
    }

    /// Returns `true` when `query` matches the name or any keyword.
    func matches(_ query: String) -> Bool {
        if name.contains(query) { return true }
        return keywords.contains { $0.hasPrefix(query) }
    }
}
