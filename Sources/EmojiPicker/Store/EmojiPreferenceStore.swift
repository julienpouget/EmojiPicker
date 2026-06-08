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
public final class EmojiPreferenceStore {

    /// A shared store backed by `UserDefaults.standard`.
    public static let shared = EmojiPreferenceStore()

    private let defaults: UserDefaults
    private let recentKey: String
    private let tonesKey: String
    private let maxRecent: Int

    public init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "EmojiPicker",
        maxRecent: Int = 30
    ) {
        self.defaults = defaults
        self.recentKey = "\(keyPrefix).recent"
        self.tonesKey = "\(keyPrefix).preferredTones"
        self.maxRecent = maxRecent
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
        let map = defaults.dictionary(forKey: tonesKey) as? [String: Int] ?? [:]
        guard let raw = map[emoji] else { return nil }
        return EmojiSkinTone(rawValue: raw)
    }

    /// Stores (or clears, when `tone` is `nil`) the preferred tone for an emoji.
    public func setPreferredTone(_ tone: EmojiSkinTone?, for emoji: String) {
        var map = defaults.dictionary(forKey: tonesKey) as? [String: Int] ?? [:]
        if let tone {
            map[emoji] = tone.rawValue
        } else {
            map.removeValue(forKey: emoji)
        }
        defaults.set(map, forKey: tonesKey)
    }
}
