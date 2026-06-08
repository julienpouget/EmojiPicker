//
//  EmojiAvailability.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// Resolves which Emoji standard version the current OS can actually render,
/// so the picker never shows tofu (□) for characters the system lacks.
///
/// The mapping follows the OS releases that shipped each Emoji version.
public enum EmojiAvailability {

    /// (minimum OS version, Emoji version it introduced), highest first.
    private static let releaseMap: [(os: OperatingSystemVersion, emoji: Double)] = [
        (.init(majorVersion: 17, minorVersion: 4, patchVersion: 0), 15.1),
        (.init(majorVersion: 16, minorVersion: 4, patchVersion: 0), 15.0),
        (.init(majorVersion: 15, minorVersion: 4, patchVersion: 0), 14.0),
        (.init(majorVersion: 14, minorVersion: 5, patchVersion: 0), 13.1),
        (.init(majorVersion: 14, minorVersion: 2, patchVersion: 0), 13.0),
        (.init(majorVersion: 13, minorVersion: 2, patchVersion: 0), 12.1),
        (.init(majorVersion: 12, minorVersion: 1, patchVersion: 0), 11.0),
    ]

    /// The highest Emoji standard version guaranteed to render on this device.
    ///
    /// Computed once from `ProcessInfo`. On platforms below the lowest mapped
    /// release this returns a conservative baseline of `5.0`.
    public static let maxAvailableVersion: Double = {
        let process = ProcessInfo.processInfo
        for entry in releaseMap where process.isOperatingSystemAtLeast(entry.os) {
            return entry.emoji
        }
        return 5.0
    }()

    /// Whether an emoji of the given standard version is renderable here.
    public static func isAvailable(version: Double) -> Bool {
        version <= maxAvailableVersion
    }
}
