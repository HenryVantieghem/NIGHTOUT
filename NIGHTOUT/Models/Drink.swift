import Foundation
import SwiftData

/// Drink entry model matching Supabase `drinks` table
@Model
final class Drink {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Drink details
    var type: DrinkType
    var customName: String?
    var customEmoji: String?

    // Timing
    var timestamp: Date

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        type: DrinkType,
        customName: String? = nil,
        customEmoji: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.nightId = nightId
        self.type = type
        self.customName = customName
        self.customEmoji = customEmoji
        self.timestamp = timestamp
    }
}

// MARK: - Drink Type
enum DrinkType: String, Codable, CaseIterable, Identifiable, Sendable {
    case beer = "beer"
    case wine = "wine"
    case cocktail = "cocktail"
    case shot = "shot"
    case spirit = "spirit"
    case cider = "cider"
    case champagne = "champagne"
    case water = "water"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beer: return "Beer"
        case .wine: return "Wine"
        case .cocktail: return "Cocktail"
        case .shot: return "Shot"
        case .spirit: return "Spirit"
        case .cider: return "Cider"
        case .champagne: return "Champagne"
        case .water: return "Water"
        case .custom: return "Custom"
        }
    }

    var emoji: String {
        switch self {
        case .beer: return "🍺"
        case .wine: return "🍷"
        case .cocktail: return "🍸"
        case .shot: return "🥃"
        case .spirit: return "🥃"
        case .cider: return "🍏"
        case .champagne: return "🥂"
        case .water: return "💧"
        case .custom: return "🍹"
        }
    }

    /// Standard drink equivalent (1 = one standard drink)
    var standardDrinks: Double {
        switch self {
        case .beer: return 1.0
        case .wine: return 1.2
        case .cocktail: return 1.5
        case .shot: return 1.0
        case .spirit: return 1.0
        case .cider: return 1.0
        case .champagne: return 1.0
        case .water: return 0.0
        case .custom: return 1.0
        }
    }
}

// MARK: - DrinkType SwiftUI Color Extension
import SwiftUI

extension DrinkType {
    /// Skeuomorphic color for each drink type
    var color: Color {
        switch self {
        case .beer: return Color(red: 0.96, green: 0.76, blue: 0.26) // Golden amber
        case .wine: return Color(red: 0.55, green: 0.09, blue: 0.19) // Deep burgundy
        case .cocktail: return Color(red: 0.0, green: 0.75, blue: 1.0) // Electric blue
        case .shot: return Color(red: 0.65, green: 0.45, blue: 0.20) // Whiskey brown
        case .spirit: return Color(red: 0.65, green: 0.45, blue: 0.20) // Whiskey brown
        case .cider: return Color(red: 0.55, green: 0.78, blue: 0.25) // Apple green
        case .champagne: return Color(red: 0.96, green: 0.87, blue: 0.70) // Champagne gold
        case .water: return Color(red: 0.53, green: 0.81, blue: 0.92) // Light blue
        case .custom: return Color(red: 0.75, green: 0.0, blue: 1.0) // Party purple
        }
    }
}

// MARK: - Computed Properties
extension Drink {
    @MainActor
    var displayEmoji: String {
        customEmoji ?? type.emoji
    }

    @MainActor
    var displayName: String {
        customName ?? type.displayName
    }
}
