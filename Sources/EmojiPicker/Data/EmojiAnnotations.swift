//
//  EmojiAnnotations.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// Locale-specific emoji names and extra search keywords, loaded from the
/// bundled `annotations-<locale>.json` resources (generated from CLDR by
/// `Scripts/generate-emoji-data.py --annotations`).
///
/// The dataset's own names and keywords are English; this layer adds the
/// user's language on top: localized display/VoiceOver names and additional
/// search keywords (so "coeur" finds ❤️ in French, "+1" finds 👍 in English).
struct EmojiAnnotations {

    /// Annotations for the bundle's preferred localization, resolved once.
    /// Falls back to an empty set when no annotations resource exists for
    /// that language — search then runs on the dataset's English terms only.
    static let current = EmojiAnnotations(
        localization: Bundle.module.preferredLocalizations.first ?? "en"
    )

    struct Entry {
        /// Localized display name; `nil` when it folds to the dataset name.
        let name: String?
        /// Folded form of `name`, kept for whole-query substring matching.
        let foldedName: String?
        /// Pre-folded search keyword tokens (folded at generation time).
        let keywords: [String]
    }

    let locale: String
    /// The locale's grammatical words excluded from the stored keywords. The
    /// view model strips the same words from query tokens, so a CLDR phrase
    /// typed verbatim ("visage qui rougit") still matches its stored tokens.
    let stopwords: Set<String>
    private let entries: [String: Entry]

    init(localization: String) {
        self.locale = localization
        guard
            let url = Bundle.module.url(
                forResource: "annotations-\(localization)", withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(File.self, from: data)
        else {
            self.stopwords = []
            self.entries = [:]
            return
        }
        self.stopwords = Set(decoded.stopwords ?? [])
        self.entries = decoded.annotations.mapValues { raw in
            Entry(
                name: raw.n,
                foldedName: raw.n?.searchFolded,
                keywords: raw.k ?? []
            )
        }
    }

    var isEmpty: Bool { entries.isEmpty }

    /// The localized display name for a base emoji value, if it differs from
    /// the dataset's (English) name.
    func name(for value: String) -> String? {
        entries[value]?.name
    }

    /// Whether a search query matches an emoji, across its English vocabulary
    /// (Unicode name + dataset keywords) and this locale's annotations.
    ///
    /// `query` must be search-folded and `tokens` its word tokens with this
    /// locale's stopwords removed (see ``EmojiPickerViewModel``). The whole
    /// query is first tried as a substring of either name, so natural phrases
    /// match directly. Otherwise every token must match — as a substring of
    /// either name or a prefix of a keyword from *either* vocabulary, so
    /// mixed queries like "blond-haired" (name word + annotation word) and
    /// word order both work. A query with no tokens (pure symbols like "+"
    /// or "...") falls back to exact keyword equality.
    func matches(_ emoji: Emoji, query: String, tokens: [String]) -> Bool {
        let entry = entries[emoji.value]
        if emoji.searchName.contains(query) { return true }
        if let folded = entry?.foldedName, folded.contains(query) { return true }
        guard !tokens.isEmpty else {
            return emoji.searchKeywords.contains(query)
                || entry?.keywords.contains(query) == true
        }
        return tokens.allSatisfy { token in
            emoji.searchName.contains(token)
                || emoji.searchKeywords.contains { $0.hasPrefix(token) }
                || entry?.foldedName?.contains(token) == true
                || entry?.keywords.contains { $0.hasPrefix(token) } == true
        }
    }

    /// Decodable mirror of `annotations-<locale>.json`.
    private struct File: Decodable {
        let locale: String
        let stopwords: [String]?
        let annotations: [String: RawEntry]

        struct RawEntry: Decodable {
            let n: String?
            let k: [String]?
        }
    }
}
