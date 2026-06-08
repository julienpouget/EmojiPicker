//
//  EmojiData.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// Decodable mirror of the bundled `emojis.json` resource.
struct EmojiData: Decodable {
    let unicodeVersion: String
    let categories: [Category]

    struct Category: Decodable {
        let id: String
        let emojis: [Entry]
    }

    struct Entry: Decodable {
        let value: String
        let name: String
        let version: Double
        let keywords: [String]
        let tones: [String: String]?

        enum CodingKeys: String, CodingKey {
            case value = "e"
            case name = "n"
            case version = "v"
            case keywords = "k"
            case tones = "t"
        }

        /// Converts a raw JSON entry into a domain `Emoji`.
        func makeEmoji(in category: EmojiCategory) -> Emoji {
            var variants: [EmojiSkinTone: String] = [:]
            if let tones {
                for (key, glyph) in tones {
                    if let index = Int(key), let tone = EmojiSkinTone(rawValue: index) {
                        variants[tone] = glyph
                    }
                }
            }
            return Emoji(
                value: value,
                name: name,
                version: version,
                keywords: keywords,
                skinVariants: variants,
                category: category
            )
        }
    }
}
