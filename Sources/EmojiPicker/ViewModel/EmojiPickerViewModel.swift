//
//  EmojiPickerViewModel.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import SwiftUI

/// Drives the picker UI: builds the visible sections, filters search results,
/// resolves preferred skin tones, and records selections.
@MainActor
final class EmojiPickerViewModel: ObservableObject {

    /// A grid entry: an emoji resolved to the concrete tone it should render in.
    struct Item: Identifiable, Hashable {
        let emoji: Emoji
        let tone: EmojiSkinTone?

        var glyph: String { emoji.string(for: tone) }
        /// Identity is the rendered glyph so toned variants stay distinct.
        var id: String { glyph }
    }

    /// A renderable section: a category header plus its items.
    struct Section: Identifiable {
        let category: EmojiCategory
        let items: [Item]
        var id: String { category.id }
    }

    @Published var searchText: String = ""
    @Published private(set) var sections: [Section] = []

    private let store: EmojiPreferenceStore
    private let config: EmojiPickerConfiguration

    init(store: EmojiPreferenceStore, config: EmojiPickerConfiguration) {
        self.store = store
        self.config = config
        rebuild()
    }

    /// The categories that have a tab, derived from the visible sections.
    var tabCategories: [EmojiCategory] {
        sections.map(\.category)
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Recomputes sections for the current search text and recents.
    func rebuild() {
        let query = searchText
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        if query.isEmpty {
            var result: [Section] = []
            if config.showsRecents {
                let recents = resolvedRecents()
                if !recents.isEmpty {
                    result.append(Section(category: .recent, items: recents))
                }
            }
            for group in EmojiProvider.categorized {
                result.append(Section(category: group.category, items: group.emojis.map(makeItem)))
            }
            sections = result
        } else {
            let matches = EmojiProvider.all.filter { $0.matches(query) }
            sections = matches.isEmpty
                ? []
                : [Section(category: .smileysAndPeople, items: matches.map(makeItem))]
        }
    }

    /// The tone an emoji should render with, read from the persisted preference.
    func displayTone(for emoji: Emoji) -> EmojiSkinTone? {
        guard emoji.supportsSkinTones else { return nil }
        return store.preferredTone(for: emoji.value)
    }

    /// Records a selection from an item and returns the concrete glyph.
    func select(_ item: Item) -> String {
        store.registerSelection(item.glyph)
        return item.glyph
    }

    /// Records a selection from an emoji using its preferred tone.
    func select(_ emoji: Emoji) -> String {
        select(makeItem(for: emoji))
    }

    /// Persists a per-emoji tone choice and refreshes the grid.
    func setPreferredTone(_ tone: EmojiSkinTone?, for emoji: Emoji) {
        store.setPreferredTone(tone, for: emoji.value)
        rebuild()
    }

    // MARK: Helpers

    /// Wraps an emoji with its currently preferred tone.
    private func makeItem(for emoji: Emoji) -> Item {
        Item(emoji: emoji, tone: displayTone(for: emoji))
    }

    /// Resolves stored recent glyphs (which may be toned) into items, keeping
    /// the exact tone each was selected with — independent of global prefs.
    private func resolvedRecents() -> [Item] {
        store.recent.compactMap { glyph in
            if let base = EmojiProvider.byValue[glyph] {
                return Item(emoji: base, tone: nil)
            }
            if let (base, tone) = baseAndTone(for: glyph) {
                return Item(emoji: base, tone: tone)
            }
            return nil
        }
    }

    /// Finds the base emoji and tone for a toned glyph stored in recents.
    private func baseAndTone(for glyph: String) -> (Emoji, EmojiSkinTone)? {
        for emoji in EmojiProvider.all where emoji.supportsSkinTones {
            for (tone, variant) in emoji.skinVariants where variant == glyph {
                return (emoji, tone)
            }
        }
        return nil
    }
}
