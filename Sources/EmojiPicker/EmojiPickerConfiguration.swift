//
//  EmojiPickerConfiguration.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// The backdrop drawn behind the picker. Materials adapt to light/dark
/// automatically and blur whatever sits behind the picker.
public enum EmojiPickerBackground: Sendable {
    /// Translucent, theme-aware blur (the default — matches the macOS panel).
    case ultraThinMaterial
    case thinMaterial
    case regularMaterial
    case thickMaterial
    /// Opaque system background (no translucency).
    case solid
}

/// Controls which Emoji standard versions the picker offers.
///
/// In every case the effective ceiling is also capped by what the *current
/// device* can render, so the picker never shows tofu (□) regardless of policy.
public enum EmojiVersionPolicy: Sendable, Equatable {
    /// Show everything the current device can render (default). Maximises the
    /// set per device; the offered set therefore differs across OS versions.
    case device

    /// Cap at the highest Emoji version guaranteed on every OS at or above the
    /// given deployment target, so all devices down to that OS show the *same*
    /// set. E.g. `.minimumOS(major: 15, minor: 0)` for an iOS 15 app.
    case minimumOS(major: Int, minor: Int)

    /// Cap at an explicit Emoji standard version (e.g. `15.0`), for instance to
    /// match a backend that only stores up to a given version.
    case maxEmojiVersion(Double)
}

/// Tunable appearance and behaviour for the picker.
public struct EmojiPickerConfiguration: Sendable {

    /// Point size used to render each emoji glyph, at the default Dynamic Type
    /// size. The rendered size follows the user's text-size setting.
    public var emojiFontSize: CGFloat

    /// Minimum width allotted to a grid cell; the grid lays out as many columns
    /// as fit. Cells are square. Specified at the default Dynamic Type size and
    /// scaled with the user's text-size setting, in step with the glyphs.
    public var minimumCellSize: CGFloat

    /// Spacing between grid cells.
    public var cellSpacing: CGFloat

    /// Accent colour for the selected category tab and search affordances.
    public var accentColor: Color

    /// Whether to show the search field at the top.
    public var showsSearchBar: Bool

    /// Whether to show the recently-used section and its tab.
    public var showsRecents: Bool

    /// Whether long-pressing a tone-capable emoji reveals the skin-tone picker.
    public var allowsSkinToneSelection: Bool

    /// Dismiss the picker immediately after a selection is made.
    public var dismissesOnSelection: Bool

    /// The backdrop drawn behind the picker.
    public var background: EmojiPickerBackground

    /// Which Emoji standard versions to offer (always capped by the device).
    public var versionPolicy: EmojiVersionPolicy

    public init(
        emojiFontSize: CGFloat = 30,
        minimumCellSize: CGFloat = 44,
        cellSpacing: CGFloat = 4,
        accentColor: Color = .accentColor,
        showsSearchBar: Bool = true,
        showsRecents: Bool = true,
        allowsSkinToneSelection: Bool = true,
        dismissesOnSelection: Bool = true,
        background: EmojiPickerBackground = .ultraThinMaterial,
        versionPolicy: EmojiVersionPolicy = .device
    ) {
        self.emojiFontSize = emojiFontSize
        self.minimumCellSize = minimumCellSize
        self.cellSpacing = cellSpacing
        self.accentColor = accentColor
        self.showsSearchBar = showsSearchBar
        self.showsRecents = showsRecents
        self.allowsSkinToneSelection = allowsSkinToneSelection
        self.dismissesOnSelection = dismissesOnSelection
        self.background = background
        self.versionPolicy = versionPolicy
    }

    public static let `default` = EmojiPickerConfiguration()
}
