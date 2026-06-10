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

    func testAvailabilityMinimumOSMapping() {
        // Highest Emoji version guaranteed on every OS at or above the target.
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 26, 4), 17.0)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 18, 4), 16.0)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 17, 4), 15.1)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 16, 4), 15.0)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 15, 4), 14.0)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 15, 0), 13.1)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 12, 1), 11.0)
        XCTAssertEqual(EmojiAvailability.maxVersion(forOSAtLeast: 11, 0), 5.0, "Below the lowest mapped OS falls back to the baseline")
    }

    @MainActor
    func testDefaultPolicyNeverExceedsDeviceVersion() {
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        let vm = EmojiPickerViewModel(store: store, config: .default) // .device policy

        let max = EmojiAvailability.maxAvailableVersion
        for section in vm.sections {
            for item in section.items {
                XCTAssertLessThanOrEqual(item.emoji.version, max)
            }
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
        XCTAssertTrue(searchMatches(heart, "heart"))
        XCTAssertFalse(searchMatches(heart, "zzzzz"))
    }

    func testSearchIsCaseAndDiacriticInsensitive() throws {
        let pinata = try XCTUnwrap(EmojiProvider.byValue["🪅"])
        XCTAssertEqual(pinata.name, "piñata")
        XCTAssertTrue(searchMatches(pinata, "pinata"), "Folded query matches an accented name")
        XCTAssertTrue(searchMatches(pinata, "PIÑATA"), "Case and accents fold together")
    }

    func testSearchTokenizesLikeTheGenerator() {
        XCTAssertEqual("drapeau : france".searchTokens, ["drapeau", "france"])
        XCTAssertEqual("j'adore".searchFolded.searchTokens, ["adore"], "Single letters drop, words stay")
        XCTAssertEqual("12:30".searchTokens, ["12", "30"], "Digits survive even alone")
        XCTAssertEqual("+1".searchTokens, ["+1"], "The + sign is part of the token")
        XCTAssertEqual("...".searchTokens, [], "Pure punctuation yields no tokens")
    }

    @MainActor
    func testViewModelSearchFoldsTheQuery() throws {
        guard EmojiAvailability.maxAvailableVersion >= 13 else {
            throw XCTSkip("Test host can't render Emoji 13+ (piñata)")
        }
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        let vm = EmojiPickerViewModel(store: store, config: .default)

        vm.searchText = "PINATA"
        XCTAssertTrue(
            vm.sections.flatMap(\.items).contains { $0.emoji.value == "🪅" },
            "An unaccented uppercase query should find piñata"
        )
    }

    func testSearchIsWordOrderInsensitive() throws {
        let thumbsUp = try XCTUnwrap(EmojiProvider.byValue["👍"])
        XCTAssertTrue(searchMatches(thumbsUp, "thumbs up"), "Phrase substring on the name")
        XCTAssertTrue(searchMatches(thumbsUp, "up thumbs"), "Tokens match regardless of order")
        XCTAssertFalse(searchMatches(thumbsUp, "up rocket"), "Every token must match")
    }

    func testTonedRecentResolvesViaReverseIndex() throws {
        let match = try XCTUnwrap(EmojiProvider.byTonedValue["👋🏿"])
        XCTAssertEqual(match.emoji.value, "👋")
        XCTAssertEqual(match.tone, .dark)
        XCTAssertNil(EmojiProvider.byTonedValue["😀"], "A non-toned glyph has no reverse entry")
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
    func testMaxEmojiVersionPolicyCapsBelowDevice() throws {
        // The device (test sim) can render >= 14.0; cap the picker at 13.0.
        guard EmojiAvailability.maxAvailableVersion >= 14 else {
            throw XCTSkip("Test host can't render Emoji 14+, nothing to cap below")
        }
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        let config = EmojiPickerConfiguration(versionPolicy: .maxEmojiVersion(13.0))
        let vm = EmojiPickerViewModel(store: store, config: config)

        let visible = vm.sections.flatMap { $0.items }
        XCTAssertFalse(visible.isEmpty)
        for item in visible {
            XCTAssertLessThanOrEqual(item.emoji.version, 13.0)
        }
        // 🫠 melting face is Emoji 14.0 → renderable on the device but excluded by the cap.
        XCTAssertFalse(visible.contains { $0.emoji.value == "🫠" }, "14.0 emoji must be capped out")
        XCTAssertTrue(visible.contains { $0.emoji.value == "😀" }, "1.0 emoji stays visible")
    }

    @MainActor
    func testMinimumOSPolicyCaps() throws {
        guard EmojiAvailability.maxAvailableVersion >= 14 else {
            throw XCTSkip("Test host can't render Emoji 14+")
        }
        let suite = "EmojiPickerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        // An iOS 15.0 deployment target → Emoji 13.1 ceiling for the whole fleet.
        let config = EmojiPickerConfiguration(versionPolicy: .minimumOS(major: 15, minor: 0))
        let vm = EmojiPickerViewModel(store: store, config: config)

        for item in vm.sections.flatMap(\.items) {
            XCTAssertLessThanOrEqual(item.emoji.version, 13.1)
        }
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
