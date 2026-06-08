//
//  ModelTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Covers the pure value types: `EmojiCategory`, `EmojiSkinTone`, and `Emoji`
/// identity — small surfaces that are easy to break silently (a missing
/// localization key, a wrong Fitzpatrick scalar) and cheap to pin down.
final class ModelTests: XCTestCase {

    // MARK: EmojiCategory

    func testEveryCategoryResolvesAStableSystemImage() {
        for category in EmojiCategory.allCases {
            XCTAssertFalse(category.systemImageName.isEmpty, "\(category) has no SF Symbol")
        }
    }

    func testEveryCategoryTitleIsLocalized() {
        // A missing key makes NSLocalizedString echo the raw key back, which
        // would surface in the UI — assert the lookup actually resolved.
        for category in EmojiCategory.allCases {
            let title = category.title
            XCTAssertFalse(title.isEmpty, "\(category) title is empty")
            XCTAssertFalse(
                title.hasPrefix("category."),
                "\(category) title returned the raw key — localization missing"
            )
        }
    }

    func testDataCategoriesExcludeRecentAndAreInDisplayOrder() {
        XCTAssertFalse(EmojiCategory.dataCategories.contains(.recent))
        XCTAssertEqual(EmojiCategory.dataCategories, [
            .smileysAndPeople, .animalsAndNature, .foodAndDrink, .activities,
            .travelAndPlaces, .objects, .symbols, .flags,
        ])
    }

    func testCategoryIdMatchesRawValue() {
        for category in EmojiCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    // MARK: EmojiSkinTone

    func testSkinToneModifiersAreTheFitzpatrickScalars() {
        XCTAssertEqual(EmojiSkinTone.light.modifier, "\u{1F3FB}")
        XCTAssertEqual(EmojiSkinTone.mediumLight.modifier, "\u{1F3FC}")
        XCTAssertEqual(EmojiSkinTone.medium.modifier, "\u{1F3FD}")
        XCTAssertEqual(EmojiSkinTone.mediumDark.modifier, "\u{1F3FE}")
        XCTAssertEqual(EmojiSkinTone.dark.modifier, "\u{1F3FF}")
    }

    func testSkinToneRawValuesMatchTheDatasetToneIndices() {
        XCTAssertEqual(EmojiSkinTone.allCases.map(\.rawValue), [0, 1, 2, 3, 4])
        for tone in EmojiSkinTone.allCases {
            XCTAssertEqual(tone.id, tone.rawValue)
        }
    }

    func testEverySkinToneHasAnAccessibilityName() {
        for tone in EmojiSkinTone.allCases {
            let name = tone.accessibilityName
            XCTAssertFalse(name.isEmpty, "\(tone) has no accessibility name")
            // A missing .strings entry makes NSLocalizedString echo the key back,
            // so assert the key actually resolved to a localized value.
            XCTAssertFalse(name.hasPrefix("tone."), "\(tone) accessibility name is an unresolved key: \(name)")
        }
    }

    // MARK: Emoji identity

    func testEmojiIdentityIsItsDefaultValue() throws {
        let wave = try XCTUnwrap(EmojiProvider.byValue["👋"])
        XCTAssertEqual(wave.id, wave.value)
    }
}
