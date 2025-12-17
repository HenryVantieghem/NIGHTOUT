import Foundation

/// Drink entry DTO for Supabase
struct SupabaseDrink: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let type: String
    let customName: String?
    let customEmoji: String?
    let timestamp: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case type
        case customName = "custom_name"
        case customEmoji = "custom_emoji"
        case timestamp
        case createdAt = "created_at"
    }
}

/// Drink insert DTO
struct SupabaseDrinkInsert: Codable, Sendable {
    let nightId: UUID
    let type: String
    let customName: String?
    let customEmoji: String?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case type
        case customName = "custom_name"
        case customEmoji = "custom_emoji"
        case timestamp
    }

    init(
        nightId: UUID,
        type: DrinkType,
        customName: String? = nil,
        customEmoji: String? = nil
    ) {
        self.nightId = nightId
        self.type = type.rawValue
        self.customName = customName
        self.customEmoji = customEmoji
        self.timestamp = Date()
    }
}
