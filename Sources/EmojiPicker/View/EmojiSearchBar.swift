//
//  EmojiSearchBar.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// A lightweight search field styled to match the system look, usable on iOS 15.
struct EmojiSearchBar: View {
    @Binding var text: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(searchPlaceholder, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(clearLabel))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accentColor(accent)
    }

    private var searchPlaceholder: String {
        NSLocalizedString("search.placeholder", bundle: .module, comment: "")
    }

    private var clearLabel: String {
        NSLocalizedString("search.clear", bundle: .module, comment: "")
    }
}
