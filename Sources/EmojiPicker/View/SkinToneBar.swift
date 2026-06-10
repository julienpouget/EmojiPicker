//
//  SkinToneBar.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// A floating, macOS-style callout of skin-tone choices shown next to a
/// long-pressed emoji, with a caret pointing back at it.
struct SkinToneBar: View {
    let emoji: Emoji
    let selected: EmojiSkinTone?
    let configuration: EmojiPickerConfiguration
    /// Which edge the caret sits on: `.bottom` when the bar is above the emoji,
    /// `.top` when it had to flip below it.
    let caretEdge: Edge
    /// The global x-coordinate the caret should point at (the emoji's centre).
    let caretTargetX: CGFloat
    let onSelect: (EmojiSkinTone?) -> Void

    // Matches the grid cells' Dynamic Type scaling so the callout's tone
    // glyphs render at the same size as the pressed emoji.
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    /// Height reserved on the caret side of the bubble for the caret.
    static let caretHeight: CGFloat = 9

    /// Accessibility label for the default (yellow) presentation choice.
    static let defaultToneLabel = NSLocalizedString("tone.default", bundle: .module, comment: "")

    /// Choices: default (yellow) first, then every supported tone.
    private var choices: [EmojiSkinTone?] {
        [nil] + EmojiSkinTone.allCases.filter { emoji.skinVariants[$0] != nil }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(choices.enumerated()), id: \.offset) { _, tone in
                Button {
                    onSelect(tone)
                } label: {
                    Text(emoji.string(for: tone))
                        .font(.system(size: configuration.emojiFontSize * typeScale))
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(tone == selected
                                      ? configuration.accentColor.opacity(0.3)
                                      : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tone?.accessibilityName ?? Self.defaultToneLabel))
            }
        }
        .padding(6)
        .padding(caretEdge == .top ? .top : .bottom, Self.caretHeight)
        .background(calloutBackground)
    }

    private var calloutBackground: some View {
        GeometryReader { geo in
            // Resolve the caret's x within the bubble, so it points at the
            // emoji even when the bubble is clamped against a screen edge.
            let localCaretX = caretTargetX - geo.frame(in: .global).minX
            let shape = CalloutBubble(
                caretEdge: caretEdge,
                caretHeight: Self.caretHeight,
                caretCenterX: localCaretX
            )
            shape
                .fill(.ultraThinMaterial)
                .overlay(
                    // Hairline edge for definition over busy content.
                    shape.stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                )
                .compositingGroup()
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
        }
    }
}

/// A rounded-rect bubble with a caret on the top or bottom edge.
private struct CalloutBubble: Shape {
    var caretEdge: Edge = .bottom
    var cornerRadius: CGFloat = 14
    var caretWidth: CGFloat = 18
    var caretHeight: CGFloat = 9
    /// Desired caret centre (in the shape's coordinate space). Clamped to fit.
    var caretCenterX: CGFloat?

    func path(in rect: CGRect) -> Path {
        let onTop = caretEdge == .top
        let bubble = CGRect(
            x: rect.minX,
            y: onTop ? rect.minY + caretHeight : rect.minY,
            width: rect.width,
            height: max(rect.height - caretHeight, 0)
        )
        var path = Path(roundedRect: bubble, cornerRadius: cornerRadius, style: .continuous)

        let minX = bubble.minX + cornerRadius + caretWidth / 2
        let maxX = bubble.maxX - cornerRadius - caretWidth / 2
        let desired = caretCenterX ?? rect.midX
        let centerX = max(minX, min(desired, maxX))

        let half = caretWidth / 2
        let baseY = onTop ? bubble.minY : bubble.maxY
        let apex = CGPoint(x: centerX, y: onTop ? baseY - caretHeight : baseY + caretHeight)
        let left = CGPoint(x: centerX - half, y: baseY)
        let right = CGPoint(x: centerX + half, y: baseY)

        // Round just the tip: stop short of the apex along each edge and sweep
        // a quadratic curve through it, like the native popover's softened point.
        let tipRadius = min(3, caretHeight / 2)
        let p1 = point(from: apex, toward: left, distance: tipRadius)
        let p2 = point(from: apex, toward: right, distance: tipRadius)

        var caret = Path()
        caret.move(to: left)
        caret.addLine(to: p1)
        caret.addQuadCurve(to: p2, control: apex)
        caret.addLine(to: right)
        caret.closeSubpath()
        path.addPath(caret)
        return path
    }

    /// A point `distance` away from `a` along the direction toward `b`.
    private func point(from a: CGPoint, toward b: CGPoint, distance: CGFloat) -> CGPoint {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = max((dx * dx + dy * dy).squareRoot(), 0.0001)
        return CGPoint(x: a.x + dx / length * distance, y: a.y + dy / length * distance)
    }
}
