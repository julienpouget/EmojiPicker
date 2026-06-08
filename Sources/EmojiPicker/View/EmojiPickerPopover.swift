//
//  EmojiPickerPopover.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

public extension View {

    /// Presents the emoji picker as a popover with an arrow pointing at this view.
    ///
    /// Uses SwiftUI's native popover — no UIKit. On **iPad** (every version) and
    /// **iPhone on iOS 16.4+**, this is a true popover with an arrow. On
    /// **iPhone running iOS 15.0–16.3**, where SwiftUI can't render a compact
    /// popover, it falls back to a filling sheet.
    ///
    /// - Parameters:
    ///   - isPresented: Binding controlling presentation.
    ///   - arrowEdge: The edge of this view the popover's arrow points from.
    ///   - contentSize: Popover size where a popover is shown (ignored by the
    ///     sheet fallback, which fills the sheet).
    ///   - configuration: Appearance and behaviour overrides.
    ///   - store: Persistence store for recents and skin-tone preferences.
    ///   - onSelection: Called with the chosen emoji string (including skin tone).
    func emojiPickerPopover(
        isPresented: Binding<Bool>,
        arrowEdge: Edge = .top,
        contentSize: CGSize = CGSize(width: 340, height: 400),
        configuration: EmojiPickerConfiguration = .default,
        store: EmojiPreferenceStore = .shared,
        onSelection: @escaping (String) -> Void
    ) -> some View {
        modifier(EmojiPickerPopoverModifier(
            isPresented: isPresented,
            arrowEdge: arrowEdge,
            contentSize: contentSize,
            configuration: configuration,
            store: store,
            onSelection: onSelection
        ))
    }

    /// Popover variant that writes the selection into a binding.
    func emojiPickerPopover(
        isPresented: Binding<Bool>,
        selection: Binding<String>,
        arrowEdge: Edge = .top,
        contentSize: CGSize = CGSize(width: 340, height: 400),
        configuration: EmojiPickerConfiguration = .default,
        store: EmojiPreferenceStore = .shared
    ) -> some View {
        emojiPickerPopover(
            isPresented: isPresented,
            arrowEdge: arrowEdge,
            contentSize: contentSize,
            configuration: configuration,
            store: store,
            onSelection: { selection.wrappedValue = $0 }
        )
    }
}

private struct EmojiPickerPopoverModifier: ViewModifier {
    @Binding var isPresented: Bool
    let arrowEdge: Edge
    let contentSize: CGSize
    let configuration: EmojiPickerConfiguration
    let store: EmojiPreferenceStore
    let onSelection: (String) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        if usesNativePopover {
            content.popover(isPresented: $isPresented, arrowEdge: arrowEdge) {
                popoverContent
            }
        } else {
            content.sheet(isPresented: $isPresented) {
                sheetContent
            }
        }
    }

    /// A native popover renders an arrow in regular width (iPad) on every
    /// version, and in compact width (iPhone) only from iOS 16.4 via
    /// `presentationCompactAdaptation`. Below that, compact falls back to a sheet.
    private var usesNativePopover: Bool {
        if #available(iOS 16.4, *) { return true }
        return sizeClass != .compact
    }

    @ViewBuilder
    private var popoverContent: some View {
        // Fix the width but only cap the height: the system may grant a shorter
        // popover than contentSize.height (depending on where the anchor sits),
        // and a fixed height would overflow and clip the search/category bars.
        let picker = makePicker(configuration: presentedConfiguration)
            .frame(width: contentSize.width)
            .frame(maxHeight: contentSize.height)

        if #available(iOS 16.4, *) {
            picker.presentationCompactAdaptation(.popover)
        } else {
            picker
        }
    }

    private var sheetContent: some View {
        makePicker(configuration: presentedConfiguration)
    }

    private func makePicker(configuration config: EmojiPickerConfiguration) -> EmojiPickerView {
        EmojiPickerView(configuration: config, store: store) { emoji in
            onSelection(emoji)
            if configuration.dismissesOnSelection { isPresented = false }
        }
    }

    /// Same configuration as the caller asked for (matching the sheet and inline
    /// pickers' backdrop); dismissal is driven here via the binding rather than
    /// the picker's `dismiss` environment.
    private var presentedConfiguration: EmojiPickerConfiguration {
        var config = configuration
        config.dismissesOnSelection = false
        return config
    }
}
