//
//  Haptics.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Thin wrapper around platform haptic feedback, a no-op where unavailable.
enum Haptics {
    static func impact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
