//
//  EmojiCategory.swift
//  EmojiPicker
//
//  Copyright © 2026 Julien Pouget.
//  Licensed under the MIT License. See LICENSE.
//

import Foundation

/// The top-level sections shown in the picker, in display order.
///
/// `recent` is a synthetic category populated from the user's selection
/// history rather than from the static dataset.
public enum EmojiCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case recent
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case activities
    case travelAndPlaces
    case objects
    case symbols
    case flags

    public var id: String { rawValue }

    /// The categories backed by the static dataset, in display order.
    public static let dataCategories: [EmojiCategory] = [
        .smileysAndPeople, .animalsAndNature, .foodAndDrink, .activities,
        .travelAndPlaces, .objects, .symbols, .flags,
    ]

    /// An SF Symbol name representing the category in the tab bar.
    public var systemImageName: String {
        switch self {
        case .recent: return "clock"
        case .smileysAndPeople: return "face.smiling"
        case .animalsAndNature: return "leaf"
        case .foodAndDrink: return "cup.and.saucer"
        case .activities: return "football"
        case .travelAndPlaces: return "car"
        case .objects: return "lightbulb"
        case .symbols: return "number"
        case .flags: return "flag"
        }
    }

    /// A localized title shown in the section header.
    public var title: String {
        let key: String
        switch self {
        case .recent: key = "category.recent"
        case .smileysAndPeople: key = "category.smileysAndPeople"
        case .animalsAndNature: key = "category.animalsAndNature"
        case .foodAndDrink: key = "category.foodAndDrink"
        case .activities: key = "category.activities"
        case .travelAndPlaces: key = "category.travelAndPlaces"
        case .objects: key = "category.objects"
        case .symbols: key = "category.symbols"
        case .flags: key = "category.flags"
        }
        return NSLocalizedString(key, bundle: .module, comment: "")
    }
}
