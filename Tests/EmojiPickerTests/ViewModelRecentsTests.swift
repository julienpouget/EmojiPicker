//
//  ViewModelRecentsTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Covers the plain (non-toned) recents resolution path in the view model,
/// which the toned-recents test in `EmojiPickerTests` doesn't reach.
@MainActor
final class ViewModelRecentsTests: XCTestCase {

    private func makeStore() -> (EmojiPreferenceStore, UserDefaults, String) {
        let suite = "EmojiPickerVMRecentsTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let store = EmojiPreferenceStore(defaults: defaults, keyPrefix: "test")
        return (store, defaults, suite)
    }

    func testPlainRecentResolvesToToneFreeItem() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.registerSelection("😀") // a default-presentation recent, no tone

        let vm = EmojiPickerViewModel(store: store, config: .default)
        let recent = try XCTUnwrap(vm.sections.first { $0.category == .recent })
        let item = try XCTUnwrap(recent.items.first)

        XCTAssertEqual(item.glyph, "😀")
        XCTAssertNil(item.tone, "A plain recent carries no tone")
    }

    func testUnknownRecentGlyphIsDropped() throws {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        // A glyph that is neither a known base emoji nor a known toned variant.
        store.registerSelection("not-an-emoji")
        store.registerSelection("😀")

        let vm = EmojiPickerViewModel(store: store, config: .default)
        let recent = try XCTUnwrap(vm.sections.first { $0.category == .recent })

        XCTAssertEqual(recent.items.map(\.glyph), ["😀"], "Unresolvable recents are filtered out")
    }

    func testRecentsHiddenWhenDisabledInConfig() {
        let (store, defaults, suite) = makeStore()
        defer { defaults.removePersistentDomain(forName: suite) }

        store.registerSelection("😀")
        let config = EmojiPickerConfiguration(showsRecents: false)
        let vm = EmojiPickerViewModel(store: store, config: config)

        XCTAssertFalse(vm.sections.contains { $0.category == .recent })
    }
}
