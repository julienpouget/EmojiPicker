//
//  EmojiGridCell.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// Preference carrying the bounds of the emoji currently targeted for a
/// skin-tone selection, so the overlay bar can anchor itself to that cell.
struct SkinToneAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// A single tappable emoji in the grid.
///
/// Skin-tone-capable cells use raw tap + long-press gestures rather than a
/// `Button`, because a `Button` swallows `onLongPressGesture` so the tone bar
/// would never appear. Cells without tones keep a plain `Button` for its free
/// press highlight.
struct EmojiGridCell: View {
    let emoji: Emoji
    let tone: EmojiSkinTone?
    let configuration: EmojiPickerConfiguration
    let isToneTarget: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false

    private var glyph: String { emoji.string(for: tone) }
    private var supportsLongPress: Bool {
        configuration.allowsSkinToneSelection && emoji.supportsSkinTones
    }

    var body: some View {
        cellContent
            .anchorPreference(key: SkinToneAnchorKey.self, value: .bounds) { anchor in
                isToneTarget ? anchor : nil
            }
            .accessibilityLabel(Text(emoji.name))
            .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var cellContent: some View {
        if supportsLongPress {
            gestureGlyph
        } else {
            Button(action: onTap) {
                glyphLabel
            }
            .buttonStyle(EmojiCellButtonStyle(accent: configuration.accentColor))
            .overlay(alignment: .bottomTrailing) { toneMarker }
        }
    }

    /// Tap + long-press driven cell (used when skin tones are available).
    private var gestureGlyph: some View {
        glyphLabel
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.accentColor.opacity(isPressed ? 0.25 : 0))
            )
            .overlay(alignment: .bottomTrailing) { toneMarker }
            .contentShape(Rectangle())
            // Long press wins when held; a quick tap falls through to onTap.
            // maximumDistance keeps vertical scrolling responsive.
            .onLongPressGesture(
                minimumDuration: 0.3,
                maximumDistance: 12,
                pressing: { pressing in
                    withAnimation(.easeOut(duration: 0.12)) { isPressed = pressing }
                },
                perform: onLongPress
            )
            .onTapGesture(perform: onTap)
    }

    private var glyphLabel: some View {
        Text(glyph)
            .font(.system(size: configuration.emojiFontSize))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var toneMarker: some View {
        if supportsLongPress {
            // Subtle corner mark signalling more options on long-press.
            Triangle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 5, height: 5)
                .padding(3)
                .allowsHitTesting(false)
        }
    }
}

/// Highlights the cell background while pressed, matching the system picker.
private struct EmojiCellButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accent.opacity(configuration.isPressed ? 0.25 : 0))
            )
    }
}

/// Small bottom-right triangle used as the skin-tone affordance marker.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
