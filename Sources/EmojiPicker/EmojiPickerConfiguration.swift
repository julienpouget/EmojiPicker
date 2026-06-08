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

/// Tunable appearance and behaviour for the picker.
public struct EmojiPickerConfiguration: Sendable {

    /// Point size used to render each emoji glyph.
    public var emojiFontSize: CGFloat

    /// Minimum width allotted to a grid cell; the grid lays out as many columns
    /// as fit. Cells are square.
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

    public init(
        emojiFontSize: CGFloat = 30,
        minimumCellSize: CGFloat = 44,
        cellSpacing: CGFloat = 4,
        accentColor: Color = .accentColor,
        showsSearchBar: Bool = true,
        showsRecents: Bool = true,
        allowsSkinToneSelection: Bool = true,
        dismissesOnSelection: Bool = true,
        background: EmojiPickerBackground = .ultraThinMaterial
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
    }

    public static let `default` = EmojiPickerConfiguration()
}
