import Foundation

/// Codable DTO matching Supabase `reactions` table
struct SupabaseReaction: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let emoji: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case emoji
        case createdAt = "created_at"
    }
}

// MARK: - Insert DTO
struct SupabaseReactionInsert: Codable, Sendable {
    let nightId: UUID
    let userId: UUID
    let emoji: String

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
        case emoji
    }
}

// MARK: - Aggregated Reactions
struct ReactionCount: Identifiable, Sendable {
    let emoji: String
    let count: Int
    let hasUserReacted: Bool

    var id: String { emoji }
}

// MARK: - Common Reaction Emojis
enum ReactionEmoji: String, CaseIterable, Identifiable {
    case fire = "🔥"
    case party = "🎉"
    case heart = "❤️"
    case laugh = "😂"
    case cool = "😎"
    case cheers = "🥂"
    case clap = "👏"
    case star = "⭐️"

    var id: String { rawValue }
}
