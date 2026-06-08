//
//  EmojiSkinTone.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// A Fitzpatrick skin-tone modifier that can be applied to supported emoji.
///
/// The raw value matches the index used in the bundled emoji dataset
/// (`0`–`4`), where `nil`/absence represents the default (yellow) presentation.
public enum EmojiSkinTone: Int, CaseIterable, Codable, Sendable, Identifiable {
    case light = 0
    case mediumLight = 1
    case medium = 2
    case mediumDark = 3
    case dark = 4

    public var id: Int { rawValue }

    /// The Unicode scalar of the Fitzpatrick modifier (`U+1F3FB`–`U+1F3FF`).
    public var modifier: Character {
        switch self {
        case .light: return "\u{1F3FB}"
        case .mediumLight: return "\u{1F3FC}"
        case .medium: return "\u{1F3FD}"
        case .mediumDark: return "\u{1F3FE}"
        case .dark: return "\u{1F3FF}"
        }
    }

    /// A short, human-readable description suitable for accessibility labels.
    public var accessibilityName: String {
        switch self {
        case .light: return "light skin tone"
        case .mediumLight: return "medium-light skin tone"
        case .medium: return "medium skin tone"
        case .mediumDark: return "medium-dark skin tone"
        case .dark: return "dark skin tone"
        }
    }
}
