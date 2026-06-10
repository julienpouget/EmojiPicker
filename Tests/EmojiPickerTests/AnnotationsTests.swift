//
//  AnnotationsTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Covers the CLDR-derived per-locale annotations: resource loading, localized
/// name and keyword matching, and the invariants the generator must uphold
/// when the files are regenerated.
final class AnnotationsTests: XCTestCase {

    // MARK: Loading

    func testFrenchAndEnglishAnnotationsLoad() {
        XCTAssertFalse(EmojiAnnotations(localization: "fr").isEmpty)
        XCTAssertFalse(EmojiAnnotations(localization: "en").isEmpty)
    }

    func testUnknownLocalizationLoadsEmptyAndNeverMatches() throws {
        let annotations = EmojiAnnotations(localization: "zz")
        XCTAssertTrue(annotations.isEmpty)
        XCTAssertTrue(annotations.stopwords.isEmpty)
        XCTAssertNil(annotations.name(for: "👍"))
        let thumbsUp = try XCTUnwrap(EmojiProvider.byValue["👍"])
        XCTAssertFalse(searchMatches(thumbsUp, "pouce", annotations: annotations))
    }

    // MARK: French behaviour

    func testFrenchNamesResolve() {
        let fr = EmojiAnnotations(localization: "fr")
        XCTAssertEqual(fr.name(for: "❤️"), "cœur rouge")
        XCTAssertEqual(fr.name(for: "👍"), "pouce vers le haut")
    }

    func testFrenchSearchMatchesFoldedKeywords() throws {
        let fr = EmojiAnnotations(localization: "fr")
        let heart = try XCTUnwrap(EmojiProvider.byValue["❤️"])
        let thumbsUp = try XCTUnwrap(EmojiProvider.byValue["👍"])
        // Keywords are stored folded; the ligature in "cœur" matches "coeur".
        XCTAssertTrue(searchMatches(heart, "coeur", annotations: fr))
        XCTAssertTrue(searchMatches(heart, "cœur", annotations: fr))
        XCTAssertTrue(searchMatches(thumbsUp, "pouce", annotations: fr))
        XCTAssertTrue(searchMatches(thumbsUp, "vers le haut", annotations: fr))
        XCTAssertFalse(searchMatches(thumbsUp, "zzzzz", annotations: fr))
    }

    func testFrenchPhrasesWithStopwordsAndApostrophesMatch() throws {
        let fr = EmojiAnnotations(localization: "fr")
        // CLDR keyword phrases typed verbatim: the runtime must strip the
        // locale's stopwords ("qui") and split on apostrophes ("j'adore"),
        // exactly like the generator tokenized the stored keywords.
        let blushing = try XCTUnwrap(EmojiProvider.byValue["😊"])
        XCTAssertTrue(searchMatches(blushing, "visage qui rougit", annotations: fr))
        let hearts = try XCTUnwrap(EmojiProvider.byValue["🥰"])
        XCTAssertTrue(searchMatches(hearts, "j'adore", annotations: fr))
        XCTAssertTrue(searchMatches(hearts, "Je t'aime", annotations: fr))
    }

    func testEveryEmojiIsFindableByItsFrenchName() {
        // The strongest end-to-end property: typing an emoji's own French
        // name (verbatim, with stopwords and punctuation) must find it.
        let fr = EmojiAnnotations(localization: "fr")
        for emoji in EmojiProvider.all {
            guard let name = fr.name(for: emoji.value) else { continue }
            XCTAssertTrue(
                searchMatches(emoji, name, annotations: fr),
                "\(emoji.value) is not findable by its French name \"\(name)\""
            )
        }
    }

    func testEveryFlagIsFindableByItsFrenchCountryName() throws {
        let fr = EmojiAnnotations(localization: "fr")
        let flags = try XCTUnwrap(
            EmojiProvider.categorized.first { $0.category == .flags }?.emojis
        )
        for flag in flags {
            guard let name = fr.name(for: flag.value), name.contains(":") else { continue }
            // "drapeau : Allemagne" → country part alone must find the flag.
            let country = String(name.split(separator: ":").last!)
            XCTAssertTrue(
                searchMatches(flag, country, annotations: fr),
                "\(flag.value) is not findable by its country name \"\(country)\""
            )
        }
    }

    func testEnglishAnnotationsAddCLDRKeywords() throws {
        let en = EmojiAnnotations(localization: "en")
        let thumbsUp = try XCTUnwrap(EmojiProvider.byValue["👍"])
        // "+1" comes from CLDR, not from the dataset's name/subgroup tokens.
        XCTAssertTrue(searchMatches(thumbsUp, "+1", annotations: en))
    }

    // MARK: Generator invariants

    func testEveryAnnotatedValueExistsInTheDataset() {
        for locale in ["en", "fr"] {
            let annotations = loadRawAnnotations(locale)
            for value in annotations.keys {
                XCTAssertNotNil(
                    EmojiProvider.byValue[value],
                    "[\(locale)] annotation for \(value) has no dataset emoji"
                )
            }
        }
    }

    func testFrenchAnnotationsCoverNearlyTheWholeDataset() {
        let annotations = loadRawAnnotations("fr")
        let covered = EmojiProvider.all.filter { annotations[$0.value] != nil }.count
        let coverage = Double(covered) / Double(EmojiProvider.all.count)
        XCTAssertGreaterThan(coverage, 0.95, "French CLDR coverage dropped to \(coverage)")
    }

    func testAnnotationKeywordsArePreFoldedSingleTokens() throws {
        // The generator's fold()/tokenizer must mirror String.searchFolded and
        // .searchTokens — if they drift apart, folded and tokenized queries
        // stop matching the stored keywords.
        for locale in ["en", "fr"] {
            let stopwords = EmojiAnnotations(localization: locale).stopwords
            for (value, entry) in loadRawAnnotations(locale) {
                for keyword in entry.k ?? [] {
                    XCTAssertEqual(
                        keyword, keyword.searchFolded,
                        "[\(locale)] \(value) keyword \"\(keyword)\" is not search-folded"
                    )
                    // Either a single word token, or a pure-symbol keyword
                    // ("+", "...") matched by exact equality at runtime.
                    XCTAssertTrue(
                        keyword.searchTokens == [keyword] || keyword.searchTokens.isEmpty,
                        "[\(locale)] \(value) keyword \"\(keyword)\" is neither a single token nor a symbol"
                    )
                    XCTAssertFalse(
                        stopwords.contains(keyword),
                        "[\(locale)] \(value) keyword \"\(keyword)\" is a declared stopword"
                    )
                }
                if let name = entry.n {
                    XCTAssertFalse(name.isEmpty, "[\(locale)] \(value) has an empty name")
                }
            }
        }
    }

    func testStopwordsAreDeclaredAndFolded() {
        for locale in ["en", "fr"] {
            let annotations = EmojiAnnotations(localization: locale)
            XCTAssertFalse(annotations.stopwords.isEmpty, "[\(locale)] has no stopword list")
            for word in annotations.stopwords {
                XCTAssertEqual(word, word.searchFolded, "[\(locale)] stopword \"\(word)\" is not folded")
            }
        }
    }

    // MARK: Helpers

    private struct RawFile: Decodable {
        let locale: String
        let annotations: [String: RawEntry]
        struct RawEntry: Decodable {
            let n: String?
            let k: [String]?
        }
    }

    private func loadRawAnnotations(_ locale: String) -> [String: RawFile.RawEntry] {
        guard
            let url = Bundle.module.url(forResource: "annotations-\(locale)", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(RawFile.self, from: data)
        else {
            XCTFail("annotations-\(locale).json failed to load")
            return [:]
        }
        return decoded.annotations
    }
}
