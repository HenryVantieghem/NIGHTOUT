import Foundation
import Supabase

/// Service for content moderation and user blocking
final class ModerationService: @unchecked Sendable {
    static let shared = ModerationService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Content Reports

    /// Report content - API compatible with ReportContentView
    func reportContent(
        type: String,
        reason: String,
        description: String?,
        reportedUserId: UUID?,
        nightId: UUID?,
        commentId: UUID?
    ) async throws -> SupabaseContentReport {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let report = SupabaseContentReportInsert(
            reporterId: userId,
            reportType: type,
            reason: reason,
            description: description,
            reportedUserId: reportedUserId,
            nightId: nightId,
            commentId: commentId
        )

        let response: SupabaseContentReport = try await client
            .from("content_reports")
            .insert(report)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - User Blocking

    /// Block a user
    func blockUser(userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let block = SupabaseBlockedUserInsert(
            userId: currentUserId,
            blockedUserId: userId
        )

        try await client
            .from("blocked_users")
            .insert(block)
            .execute()

        // Also remove any existing friendship
        try await FriendshipService.shared.removeFriend(userId: userId)
    }

    /// Unblock a user
    func unblockUser(userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("blocked_users")
            .delete()
            .eq("user_id", value: currentUserId)
            .eq("blocked_user_id", value: userId)
            .execute()
    }

    /// Get blocked users
    func getBlockedUsers() async throws -> [SupabaseBlockedUser] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseBlockedUser] = try await client
            .from("blocked_users")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response
    }

    /// Check if user is blocked
    func isBlocked(userId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseBlockedUser] = try await client
            .from("blocked_users")
            .select()
            .eq("user_id", value: currentUserId)
            .eq("blocked_user_id", value: userId)
            .execute()
            .value

        return !response.isEmpty
    }
}

// MARK: - DTOs
struct SupabaseContentReport: Codable, Identifiable {
    let id: UUID
    let reporterId: UUID
    let reportType: String
    let reason: String
    let description: String?
    let reportedUserId: UUID?
    let nightId: UUID?
    let commentId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case reportType = "report_type"
        case reason
        case description
        case reportedUserId = "reported_user_id"
        case nightId = "night_id"
        case commentId = "comment_id"
        case createdAt = "created_at"
    }
}

struct SupabaseContentReportInsert: Codable {
    let reporterId: UUID
    let reportType: String
    let reason: String
    let description: String?
    let reportedUserId: UUID?
    let nightId: UUID?
    let commentId: UUID?

    enum CodingKeys: String, CodingKey {
        case reporterId = "reporter_id"
        case reportType = "report_type"
        case reason
        case description
        case reportedUserId = "reported_user_id"
        case nightId = "night_id"
        case commentId = "comment_id"
    }
}

struct SupabaseBlockedUserInsert: Codable {
    let userId: UUID
    let blockedUserId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case blockedUserId = "blocked_user_id"
    }
}
