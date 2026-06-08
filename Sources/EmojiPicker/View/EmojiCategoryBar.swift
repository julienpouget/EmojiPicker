//
//  EmojiCategoryBar.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// The bottom tab bar listing each visible category, mirroring the macOS picker.
struct EmojiCategoryBar: View {
    let categories: [EmojiCategory]
    let selected: EmojiCategory
    let accent: Color
    /// Whether the picker uses a translucent backdrop. When `false`, the bar
    /// uses an opaque background so it doesn't pick up bright content behind a
    /// popover (which a `.bar` material would, washing it out).
    let translucent: Bool
    let onSelect: (EmojiCategory) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Hairline separator from the grid, so the bar reads as a distinct
            // bar in every mode — including the opaque popover where it would
            // otherwise blend into the panel.
            Divider().opacity(0.6)

            HStack(spacing: 0) {
                ForEach(categories) { category in
                    Button {
                        onSelect(category)
                    } label: {
                        Image(systemName: category.systemImageName)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundColor(category == selected ? accent : .secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(category == selected
                                          ? accent.opacity(0.15)
                                          : Color.clear)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(category.title))
                    .accessibilityAddTraits(category == selected ? [.isButton, .isSelected] : .isButton)
                }
            }
            // Keep the selected pill clear of the container's rounded corners
            // (e.g. the popover) so it isn't clipped at the bottom edges.
            .padding(.horizontal, 10)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        // Full-bleed background: the container's rounded corners then clip the
        // bar's bottom corners to match, instead of leaving an inset gap with
        // square corners floating inside a rounded panel.
        .background(barBackground)
    }

    @ViewBuilder
    private var barBackground: some View {
        if translucent {
            Rectangle().fill(.bar)
        } else {
            Color(.systemBackground)
        }
    }
}
