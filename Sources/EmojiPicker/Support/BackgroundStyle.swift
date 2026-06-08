//
//  BackgroundStyle.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

extension View {
    /// Applies the configured backdrop, mapping the public enum to a concrete
    /// `Material` (or an opaque colour for `.solid`).
    @ViewBuilder
    func emojiPickerBackground(_ style: EmojiPickerBackground) -> some View {
        switch style {
        case .ultraThinMaterial:
            background(.ultraThinMaterial)
        case .thinMaterial:
            background(.thinMaterial)
        case .regularMaterial:
            background(.regularMaterial)
        case .thickMaterial:
            background(.thickMaterial)
        case .solid:
            background(Color(.systemBackground))
        }
    }
}
