//
//  EmojiPreferenceStore.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// Persists the user's recently-selected emoji and their preferred skin tone
/// per emoji, backed by `UserDefaults`.
///
/// All keys are namespaced so multiple independent pickers can share state, or
/// be isolated by passing a custom suite / key prefix.
///
/// Tone reads are served from an in-memory cache loaded at init, so tone
/// changes written through a *different* store instance on the same defaults
/// are not observed by this one.
///
/// `@unchecked Sendable`: `UserDefaults` is thread-safe and the mutable tone
/// cache is guarded by a lock, so instances can be shared across isolation
/// domains (e.g. created in app setup, used by main-actor pickers).
public final class EmojiPreferenceStore: @unchecked Sendable {

    /// A shared store backed by `UserDefaults.standard`.
    public static let shared = EmojiPreferenceStore()

    private let defaults: UserDefaults
    private let recentKey: String
    private let tonesKey: String
    private let maxRecent: Int

    /// In-memory mirror of the persisted tone map, written through on change.
    /// `preferredTone(for:)` runs once per emoji on every grid rebuild (each
    /// keystroke), and `UserDefaults.dictionary(forKey:)` re-bridges the whole
    /// plist dictionary on every call — too costly for that path.
    /// Guarded by `lock` (see the `Sendable` note on the class).
    private var tonesCache: [String: Int]
    private let lock = NSLock()

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "EmojiPicker",
        maxRecent: Int = 30
    ) {
        self.defaults = defaults
        self.recentKey = "\(keyPrefix).recent"
        self.tonesKey = "\(keyPrefix).preferredTones"
        self.maxRecent = maxRecent
        self.tonesCache = defaults.dictionary(forKey: tonesKey) as? [String: Int] ?? [:]
    }

    // MARK: Recents

    /// Recently selected emoji strings, most recent first.
    public var recent: [String] {
        defaults.stringArray(forKey: recentKey) ?? []
    }

    /// Records a selection, moving it to the front and trimming to the cap.
    public func registerSelection(_ emoji: String) {
        var list = recent.filter { $0 != emoji }
        list.insert(emoji, at: 0)
        if list.count > maxRecent { list.removeLast(list.count - maxRecent) }
        defaults.set(list, forKey: recentKey)
    }

    /// Clears the recents history.
    public func clearRecent() {
        defaults.removeObject(forKey: recentKey)
    }

    // MARK: Preferred skin tones

    /// The preferred skin tone for a given base emoji, if the user picked one.
    public func preferredTone(for emoji: String) -> EmojiSkinTone? {
        lock.lock()
        defer { lock.unlock() }
        guard let raw = tonesCache[emoji] else { return nil }
        return EmojiSkinTone(rawValue: raw)
    }

    /// Stores (or clears, when `tone` is `nil`) the preferred tone for an emoji.
    public func setPreferredTone(_ tone: EmojiSkinTone?, for emoji: String) {
        lock.lock()
        if let tone {
            tonesCache[emoji] = tone.rawValue
        } else {
            tonesCache.removeValue(forKey: emoji)
        }
        let snapshot = tonesCache
        lock.unlock()
        defaults.set(snapshot, forKey: tonesKey)
    }
}
