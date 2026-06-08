//
//  StoreTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Store behaviour not covered by `EmojiPickerTests`, chiefly `clearRecent()`.
final class StoreTests: XCTestCase {

    private func makeStore(maxRecent: Int = 30) -> (EmojiPreferenceStore, UserDefaults, String) {
        let suite = "EmojiPickerStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test", maxRecent: maxRecent)
        return (store, defaults, suite)
    }

    func testClearRecentEmptiesHistory() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.registerSelection("😀")
        store.registerSelection("👍")
        XCTAssertFalse(store.recent.isEmpty)

        store.clearRecent()
        XCTAssertEqual(store.recent, [])
    }

    func testClearRecentLeavesPreferredTonesIntact() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.registerSelection("👋")
        store.setPreferredTone(.medium, for: "👋")

        store.clearRecent()

        XCTAssertEqual(store.recent, [])
        XCTAssertEqual(store.preferredTone(for: "👋"), .medium, "Tones must survive a recents clear")
    }

    func testClearRecentIsIdempotentOnAnEmptyStore() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.clearRecent()
        XCTAssertEqual(store.recent, [])
    }
}
