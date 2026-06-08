//
//  EmojiProvider.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// Loads and caches the full bundled emoji dataset. The decode happens once,
/// lazily, on first access. Version filtering (per OS / per configuration) is
/// applied downstream by ``EmojiPickerViewModel`` rather than here, so a single
/// cached dataset can serve pickers with different version policies.
public enum EmojiProvider {

    /// The Unicode/Emoji dataset version bundled with the library.
    public static var unicodeVersion: String { dataset.unicodeVersion }

    /// Every bundled emoji grouped by category, in display order (unfiltered).
    public static var categorized: [(category: EmojiCategory, emojis: [Emoji])] { dataset.categorized }

    /// A flat list of every bundled emoji (unfiltered).
    public static var all: [Emoji] { dataset.all }

    /// Fast lookup of an emoji by its default (yellow) value.
    public static var byValue: [String: Emoji] { dataset.byValue }

    /// Fast reverse lookup from a toned glyph back to its base emoji and tone,
    /// e.g. `"👋🏿"` → (👋, .dark). Used to resolve toned entries in recents.
    static var byTonedValue: [String: (emoji: Emoji, tone: EmojiSkinTone)] { dataset.byTonedValue }

    /// The decoded dataset, parsed once lazily on first access. Holding it in a
    /// single immutable `let` keeps every derived view consistent and avoids the
    /// mutable global state a `static var` would introduce (data-race safe).
    private static let dataset: Dataset = load()

    private struct Dataset {
        let unicodeVersion: String
        let categorized: [(category: EmojiCategory, emojis: [Emoji])]
        let all: [Emoji]
        let byValue: [String: Emoji]
        let byTonedValue: [String: (emoji: Emoji, tone: EmojiSkinTone)]

        static let empty = Dataset(
            unicodeVersion: "?", categorized: [], all: [], byValue: [:], byTonedValue: [:]
        )
    }

    private static func load() -> Dataset {
        guard
            let url = Bundle.module.url(forResource: "emojis", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(EmojiData.self, from: data)
        else {
            assertionFailure("EmojiPicker: failed to load bundled emojis.json")
            return .empty
        }

        let categorized: [(category: EmojiCategory, emojis: [Emoji])] = decoded.categories.compactMap { raw in
            guard let category = EmojiCategory(rawValue: raw.id) else { return nil }
            let emojis = raw.emojis.map { $0.makeEmoji(in: category) }
            return emojis.isEmpty ? nil : (category, emojis)
        }

        let all = categorized.flatMap { $0.emojis }
        let byValue = Dictionary(all.map { ($0.value, $0) }, uniquingKeysWith: { first, _ in first })

        var byTonedValue: [String: (emoji: Emoji, tone: EmojiSkinTone)] = [:]
        for emoji in all where emoji.supportsSkinTones {
            for (tone, variant) in emoji.skinVariants {
                byTonedValue[variant] = (emoji, tone)
            }
        }

        return Dataset(
            unicodeVersion: decoded.unicodeVersion,
            categorized: categorized,
            all: all,
            byValue: byValue,
            byTonedValue: byTonedValue
        )
    }
}
