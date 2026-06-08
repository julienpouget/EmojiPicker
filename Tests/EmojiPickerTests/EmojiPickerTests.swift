//
//  EmojiPickerTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

final class EmojiPickerTests: XCTestCase {

    func testDatasetLoads() {
        XCTAssertFalse(EmojiProvider.all.isEmpty, "Dataset should decode and contain emojis")
        XCTAssertNotEqual(EmojiProvider.unicodeVersion, "?", "Unicode version should be populated")
    }

    func testCategoriesAreOrderedAndNonEmpty() {
        let categories = EmojiProvider.categorized.map(\.category)
        XCTAssertEqual(categories, EmojiCategory.dataCategories.filter { category in
            EmojiProvider.categorized.contains { $0.category == category }
        })
        for group in EmojiProvider.categorized {
            XCTAssertFalse(group.emojis.isEmpty)
        }
    }

    func testAvailabilityNeverExceedsDeviceVersion() {
        let max = EmojiAvailability.maxAvailableVersion
        for emoji in EmojiProvider.all {
            XCTAssertLessThanOrEqual(emoji.version, max)
        }
    }

    func testKnownEmojiHasSkinTones() throws {
        let wave = try XCTUnwrap(EmojiProvider.byValue["👋"])
        XCTAssertTrue(wave.supportsSkinTones)
        XCTAssertEqual(wave.string(for: .dark), "👋🏿")
        XCTAssertEqual(wave.string(for: nil), "👋")
    }

    func testGrinningFaceHasNoSkinTones() throws {
        let grin = try XCTUnwrap(EmojiProvider.byValue["😀"])
        XCTAssertFalse(grin.supportsSkinTones)
        XCTAssertEqual(grin.string(for: .dark), "😀", "Falls back to default when tone unsupported")
    }

    func testSearchMatchesNameAndKeywords() throws {
        let heart = try XCTUnwrap(EmojiProvider.byValue["❤️"])
        XCTAssertTrue(heart.matches("heart"))
        XCTAssertFalse(heart.matches("zzzzz"))
    }

    func testPreferenceStoreRecentsAndTones() {
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test", maxRecent: 3)

        store.registerSelection("😀")
        store.registerSelection("👍")
        store.registerSelection("😀") // moves to front, no dupe
        XCTAssertEqual(store.recent, ["😀", "👍"])

        store.registerSelection("🎉")
        store.registerSelection("🔥") // exceeds cap of 3
        XCTAssertEqual(store.recent.count, 3)
        XCTAssertEqual(store.recent.first, "🔥")

        XCTAssertNil(store.preferredTone(for: "👋"))
        store.setPreferredTone(.medium, for: "👋")
        XCTAssertEqual(store.preferredTone(for: "👋"), .medium)
        store.setPreferredTone(nil, for: "👋")
        XCTAssertNil(store.preferredTone(for: "👋"))
    }

    @MainActor
    func testViewModelToneSelectionAppliesAndPersists() throws {
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        let vm = EmojiPickerViewModel(store: store, config: .default)

        let wave = try XCTUnwrap(EmojiProvider.byValue["👋"])
        XCTAssertNil(vm.displayTone(for: wave))

        vm.setPreferredTone(.dark, for: wave)
        XCTAssertEqual(vm.displayTone(for: wave), .dark)
        XCTAssertEqual(vm.select(wave), "👋🏿", "Selection should return the toned glyph")
        XCTAssertEqual(store.preferredTone(for: "👋"), .dark, "Tone choice should persist")

        // Clearing the tone returns to the default presentation.
        vm.setPreferredTone(nil, for: wave)
        XCTAssertNil(vm.displayTone(for: wave))
        XCTAssertEqual(vm.select(wave), "👋")
    }

    @MainActor
    func testRecentsKeepTheirToneWithoutLeakingToGlobalPrefs() throws {
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        store.registerSelection("👋🏿") // a dark-toned recent, no global pref set

        let vm = EmojiPickerViewModel(store: store, config: .default)
        let wave = try XCTUnwrap(EmojiProvider.byValue["👋"])

        // The recents section renders the exact toned glyph...
        let recent = try XCTUnwrap(vm.sections.first { $0.category == .recent })
        XCTAssertEqual(recent.items.first?.glyph, "👋🏿")
        // ...but the global preference for the base emoji is untouched.
        XCTAssertNil(vm.displayTone(for: wave))
        XCTAssertNil(store.preferredTone(for: "👋"))
    }

    @MainActor
    func testViewModelSearchProducesSingleSection() {
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        let vm = EmojiPickerViewModel(store: store, config: .default)

        vm.searchText = "cat"
        vm.rebuild()
        XCTAssertTrue(vm.isSearching)
        XCTAssertEqual(vm.sections.count, 1)
        XCTAssertTrue(vm.sections.first?.items.contains { $0.emoji.name.contains("cat") } ?? false)
    }
}
