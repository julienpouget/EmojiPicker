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
    public private(set) static var unicodeVersion: String = "?"

    /// Every bundled emoji grouped by category, in display order (unfiltered).
    public static let categorized: [(category: EmojiCategory, emojis: [Emoji])] = {
        load()
    }()

    /// A flat list of every bundled emoji (unfiltered).
    public static let all: [Emoji] = {
        categorized.flatMap { $0.emojis }
    }()

    /// Fast lookup of an emoji by its default (yellow) value.
    public static let byValue: [String: Emoji] = {
        Dictionary(all.map { ($0.value, $0) }, uniquingKeysWith: { first, _ in first })
    }()

    private static func load() -> [(EmojiCategory, [Emoji])] {
        guard
            let url = Bundle.module.url(forResource: "emojis", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(EmojiData.self, from: data)
        else {
            assertionFailure("EmojiPicker: failed to load bundled emojis.json")
            return []
        }

        unicodeVersion = decoded.unicodeVersion

        return decoded.categories.compactMap { raw in
            guard let category = EmojiCategory(rawValue: raw.id) else { return nil }
            let emojis = raw.emojis.map { $0.makeEmoji(in: category) }
            return emojis.isEmpty ? nil : (category, emojis)
        }
    }
}
