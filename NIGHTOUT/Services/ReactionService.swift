import Foundation
import Supabase

/// Service for reactions and likes
final class ReactionService: @unchecked Sendable {
    static let shared = ReactionService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Likes

    /// Like a night
    func likeNight(nightId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let like = SupabaseNightLikeInsert(nightId: nightId, userId: userId)

        try await client
            .from("night_likes")
            .insert(like)
            .execute()

        // Increment like count on night
        try await incrementLikeCount(nightId: nightId)
    }

    /// Unlike a night
    func unlikeNight(nightId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("night_likes")
            .delete()
            .eq("night_id", value: nightId)
            .eq("user_id", value: userId)
            .execute()

        // Decrement like count on night
        try await decrementLikeCount(nightId: nightId)
    }

    /// Check if user has liked a night
    func hasLiked(nightId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseNightLike] = try await client
            .from("night_likes")
            .select()
            .eq("night_id", value: nightId)
            .eq("user_id", value: userId)
            .execute()
            .value

        return !response.isEmpty
    }

    /// Get like count for a night
    func getLikeCount(nightId: UUID) async throws -> Int {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseNightLike] = try await client
            .from("night_likes")
            .select()
            .eq("night_id", value: nightId)
            .execute()
            .value

        return response.count
    }

    // MARK: - Reactions

    /// Add reaction to a night
    func addReaction(nightId: UUID, emoji: String) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let reaction = SupabaseReactionInsert(nightId: nightId, userId: userId, emoji: emoji)

        try await client
            .from("reactions")
            .insert(reaction)
            .execute()
    }

    /// Remove reaction from a night
    func removeReaction(nightId: UUID, emoji: String) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("reactions")
            .delete()
            .eq("night_id", value: nightId)
            .eq("user_id", value: userId)
            .eq("emoji", value: emoji)
            .execute()
    }

    /// Get reactions for a night
    func getReactions(nightId: UUID) async throws -> [SupabaseReaction] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseReaction] = try await client
            .from("reactions")
            .select()
            .eq("night_id", value: nightId)
            .execute()
            .value

        return response
    }

    /// Get reaction counts for a night
    func getReactionCounts(nightId: UUID, currentUserId: UUID) async throws -> [ReactionCount] {
        let reactions = try await getReactions(nightId: nightId)

        var countByEmoji: [String: (count: Int, hasUserReacted: Bool)] = [:]

        for reaction in reactions {
            let emoji = reaction.emoji
            var entry = countByEmoji[emoji] ?? (count: 0, hasUserReacted: false)
            entry.count += 1
            if reaction.userId == currentUserId {
                entry.hasUserReacted = true
            }
            countByEmoji[emoji] = entry
        }

        return countByEmoji.map { emoji, entry in
            ReactionCount(emoji: emoji, count: entry.count, hasUserReacted: entry.hasUserReacted)
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Helpers

    private func incrementLikeCount(nightId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        // Get current count
        let nights: [SupabaseNight] = try await client
            .from("nights")
            .select("like_count")
            .eq("id", value: nightId)
            .execute()
            .value

        guard let night = nights.first else { return }

        // Increment
        try await client
            .from("nights")
            .update(["like_count": night.likeCount + 1])
            .eq("id", value: nightId)
            .execute()
    }

    private func decrementLikeCount(nightId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        // Get current count
        let nights: [SupabaseNight] = try await client
            .from("nights")
            .select("like_count")
            .eq("id", value: nightId)
            .execute()
            .value

        guard let night = nights.first else { return }

        // Decrement (min 0)
        try await client
            .from("nights")
            .update(["like_count": max(0, night.likeCount - 1)])
            .eq("id", value: nightId)
            .execute()
    }
}
