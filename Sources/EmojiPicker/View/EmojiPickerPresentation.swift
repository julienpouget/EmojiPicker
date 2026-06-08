//
//  EmojiPickerPresentation.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

public extension View {

    /// Presents the emoji picker as a sheet and reports each selection.
    ///
    /// - Parameters:
    ///   - isPresented: Binding controlling sheet presentation. The picker
    ///     dismisses itself automatically when ``EmojiPickerConfiguration/dismissesOnSelection``
    ///     is `true` (the default).
    ///   - configuration: Appearance and behaviour overrides.
    ///   - store: Persistence store for recents and skin-tone preferences.
    ///   - onSelection: Called with the chosen emoji string (including skin tone).
    func emojiPicker(
        isPresented: Binding<Bool>,
        configuration: EmojiPickerConfiguration = .default,
        store: EmojiPreferenceStore = .shared,
        onSelection: @escaping (String) -> Void
    ) -> some View {
        modifier(EmojiPickerSheetModifier(
            isPresented: isPresented,
            configuration: configuration,
            store: store,
            onSelection: onSelection
        ))
    }

    /// Presents the emoji picker and writes the selection into a binding.
    func emojiPicker(
        isPresented: Binding<Bool>,
        selection: Binding<String>,
        configuration: EmojiPickerConfiguration = .default,
        store: EmojiPreferenceStore = .shared
    ) -> some View {
        emojiPicker(
            isPresented: isPresented,
            configuration: configuration,
            store: store,
            onSelection: { selection.wrappedValue = $0 }
        )
    }
}

private struct EmojiPickerSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: EmojiPickerConfiguration
    let store: EmojiPreferenceStore
    let onSelection: (String) -> Void

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            sheetContent
        }
    }

    @ViewBuilder
    private var sheetContent: some View {
        let picker = EmojiPickerView(
            configuration: configuration,
            store: store,
            onSelection: onSelection
        )
        if #available(iOS 16.0, *) {
            picker.presentationDetents([.medium, .large])
        } else {
            picker
        }
    }
}
