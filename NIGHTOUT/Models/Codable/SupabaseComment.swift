import Foundation

/// Comment DTO for Supabase
struct SupabaseComment: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let authorId: UUID
    let text: String
    let timestamp: Date
    let editedAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case authorId = "author_id"
        case text
        case timestamp
        case editedAt = "edited_at"
        case createdAt = "created_at"
    }
}

/// Comment insert DTO
struct SupabaseCommentInsert: Codable, Sendable {
    let nightId: UUID
    let text: String

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case text
    }
}

/// Comment with author profile for display
struct CommentWithAuthor: Identifiable, Sendable {
    let comment: SupabaseComment
    let author: SupabaseProfile?

    var id: UUID { comment.id }
}
