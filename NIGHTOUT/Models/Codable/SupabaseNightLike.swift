import Foundation

/// Codable DTO matching Supabase `night_likes` table
struct SupabaseNightLike: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Insert DTO
struct SupabaseNightLikeInsert: Codable, Sendable {
    let nightId: UUID
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
    }
}
