//
//  DatasetInvariantsTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Guards the bundled `emojis.json` against silent corruption when it is
/// regenerated (see `Scripts/generate-emoji-data.py`). These assert structural
/// invariants the rest of the library relies on, not exact counts that churn
/// with each Unicode release — except the two the README publishes.
final class DatasetInvariantsTests: XCTestCase {

    func testEveryEmojiHasAValidValueAndName() {
        for emoji in EmojiProvider.all {
            XCTAssertFalse(emoji.value.isEmpty, "Empty value in dataset")
            XCTAssertFalse(emoji.name.isEmpty, "\(emoji.value) has no name")
            XCTAssertEqual(emoji.name, emoji.name.lowercased(), "\(emoji.value) name should be lowercased")
        }
    }

    func testEveryEmojiHasAPositiveVersionWithinTheBundledStandard() {
        let bundled = Double(EmojiProvider.unicodeVersion) ?? .greatestFiniteMagnitude
        for emoji in EmojiProvider.all {
            XCTAssertGreaterThan(emoji.version, 0, "\(emoji.value) has a non-positive version")
            XCTAssertLessThanOrEqual(
                emoji.version, bundled,
                "\(emoji.value) v\(emoji.version) exceeds the bundled standard \(bundled)"
            )
        }
    }

    func testDefaultValuesAreUnique() {
        let values = EmojiProvider.all.map(\.value)
        XCTAssertEqual(values.count, Set(values).count, "Duplicate emoji values in dataset")
    }

    func testTonedEmojiExposeAllFiveFitzpatrickVariants() {
        for emoji in EmojiProvider.all where emoji.supportsSkinTones {
            XCTAssertEqual(
                Set(emoji.skinVariants.keys), Set(EmojiSkinTone.allCases),
                "\(emoji.value) is missing skin-tone variants"
            )
            // Each variant must differ from the default and from one another.
            let variants = Set(emoji.skinVariants.values)
            XCTAssertEqual(variants.count, EmojiSkinTone.allCases.count, "\(emoji.value) has duplicate tone glyphs")
            XCTAssertFalse(variants.contains(emoji.value), "\(emoji.value) lists its base glyph as a tone variant")
        }
    }

    func testEveryDatasetCategoryMapsToAKnownCategory() {
        for group in EmojiProvider.categorized {
            XCTAssertTrue(
                EmojiCategory.dataCategories.contains(group.category),
                "\(group.category) is not a known data category"
            )
        }
    }

    /// The counts the README advertises for the bundled Unicode 17.0 dataset.
    /// Bump these alongside the README when the dataset is regenerated.
    func testPublishedCountsMatchTheReadme() {
        XCTAssertEqual(EmojiProvider.unicodeVersion, "17.0")
        XCTAssertEqual(EmojiProvider.all.count, 1914, "Total emoji count drifted from the README")
        let toned = EmojiProvider.all.filter(\.supportsSkinTones).count
        XCTAssertEqual(toned, 313, "Skin-tone emoji count drifted from the README")
    }
}
