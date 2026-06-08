//
//  AvailabilityTests.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import XCTest
@testable import EmojiPicker

/// Covers the public `isAvailable(version:)` predicate, which the OS-mapping
/// tests in `EmojiPickerTests` exercise only indirectly.
final class AvailabilityTests: XCTestCase {

    func testIsAvailableTracksTheDeviceCeiling() {
        let max = EmojiAvailability.maxAvailableVersion

        // The ceiling itself, and anything below it, must be renderable.
        XCTAssertTrue(EmojiAvailability.isAvailable(version: max))
        XCTAssertTrue(EmojiAvailability.isAvailable(version: 1.0))

        // Anything above the ceiling must be reported as unavailable.
        XCTAssertFalse(EmojiAvailability.isAvailable(version: max + 0.1))
    }

    func testIsAvailableAgreesWithTheVersionComparison() {
        let max = EmojiAvailability.maxAvailableVersion
        for version in stride(from: 1.0, through: 18.0, by: 0.5) {
            XCTAssertEqual(
                EmojiAvailability.isAvailable(version: version),
                version <= max,
                "isAvailable disagreed with the ceiling at \(version)"
            )
        }
    }
}
