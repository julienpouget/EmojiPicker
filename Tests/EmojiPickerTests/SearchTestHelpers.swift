//
//  SearchTestHelpers.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation
@testable import EmojiPicker

/// Mirrors the view model's query preparation (fold → tokenize → strip the
/// locale's stopwords) and its unified dataset + annotations matching, so
/// tests exercise exactly what a typed search does.
func searchMatches(
    _ emoji: Emoji,
    _ raw: String,
    annotations: EmojiAnnotations = EmojiAnnotations(localization: "none")
) -> Bool {
    let query = raw.trimmingCharacters(in: .whitespaces).searchFolded
    let tokens = query.searchTokens.filter { !annotations.stopwords.contains($0) }
    return annotations.matches(emoji, query: query, tokens: tokens)
}
