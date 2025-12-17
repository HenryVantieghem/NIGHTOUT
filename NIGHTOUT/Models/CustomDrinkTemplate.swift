import Foundation
import SwiftData

/// User-defined custom drink template (local only - no Supabase table)
@Model
final class CustomDrinkTemplate {
    @Attribute(.unique) var id: UUID

    // Template details
    var name: String
    var emoji: String
    var standardDrinks: Double

    // Usage tracking
    var useCount: Int
    var lastUsedAt: Date?

    // Timestamps
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        standardDrinks: Double = 1.0,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.standardDrinks = standardDrinks
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}

// MARK: - Convenience Methods
extension CustomDrinkTemplate {
    /// Create a Drink from this template
    func createDrink(nightId: UUID) -> Drink {
        Drink(
            nightId: nightId,
            type: .custom,
            customName: name,
            customEmoji: emoji
        )
    }

    /// Record usage of this template
    func recordUsage() {
        useCount += 1
        lastUsedAt = Date()
    }
}
