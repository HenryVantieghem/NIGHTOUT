import Foundation
import Supabase

/// Service for friendship operations
final class FriendshipService: @unchecked Sendable {
    static let shared = FriendshipService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get all friendships for current user
    func getFriendships() async throws -> [SupabaseFriendshipFull] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseFriendshipFull] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response
    }

    /// Get accepted friends
    func getFriends() async throws -> [SupabaseFriendshipFull] {
        let all = try await getFriendships()
        return all.filter { $0.status == "accepted" }
    }

    /// Get pending friend requests (incoming)
    func getPendingRequests() async throws -> [SupabaseFriendshipFull] {
        let all = try await getFriendships()
        return all.filter { $0.status == "pending" && $0.isIncoming }
    }

    /// Get sent friend requests (outgoing)
    func getSentRequests() async throws -> [SupabaseFriendshipFull] {
        let all = try await getFriendships()
        return all.filter { $0.status == "pending" && !$0.isIncoming }
    }

    /// Check if users are friends
    func areFriends(with userId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseFriendshipFull] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: currentUserId)
            .eq("friend_user_id", value: userId)
            .eq("status", value: "accepted")
            .execute()
            .value

        return !response.isEmpty
    }

    /// Get friendship status with a user
    func getFriendshipStatus(with userId: UUID) async throws -> FriendshipStatus? {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let response: [SupabaseFriendshipFull] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: currentUserId)
            .eq("friend_user_id", value: userId)
            .execute()
            .value

        guard let friendship = response.first else { return nil }
        return FriendshipStatus(rawValue: friendship.status)
    }

    // MARK: - Actions

    /// Send friend request
    func sendRequest(to userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Create outgoing request for current user
        let outgoing = SupabaseFriendshipInsert(
            userId: currentUserId,
            friendUserId: userId,
            status: "pending",
            isIncoming: false
        )

        // Create incoming request for other user
        let incoming = SupabaseFriendshipInsert(
            userId: userId,
            friendUserId: currentUserId,
            status: "pending",
            isIncoming: true
        )

        try await client
            .from("friendships")
            .insert([outgoing, incoming])
            .execute()
    }

    /// Accept friend request
    func acceptRequest(from userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let now = Date()
        let updateData: [String: AnyEncodable] = [
            "status": AnyEncodable("accepted"),
            "accepted_at": AnyEncodable(now)
        ]

        // Update both directions
        try await client
            .from("friendships")
            .update(updateData)
            .eq("user_id", value: currentUserId)
            .eq("friend_user_id", value: userId)
            .execute()

        try await client
            .from("friendships")
            .update(updateData)
            .eq("user_id", value: userId)
            .eq("friend_user_id", value: currentUserId)
            .execute()
    }

    /// Reject/decline friend request
    func rejectRequest(from userId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let currentUserId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Delete both directions
        try await client
            .from("friendships")
            .delete()
            .eq("user_id", value: currentUserId)
            .eq("friend_user_id", value: userId)
            .execute()

        try await client
            .from("friendships")
            .delete()
            .eq("user_id", value: userId)
            .eq("friend_user_id", value: currentUserId)
            .execute()
    }

    /// Remove friend
    func removeFriend(userId: UUID) async throws {
        // Same as reject - delete both directions
        try await rejectRequest(from: userId)
    }

    /// Cancel sent request
    func cancelRequest(to userId: UUID) async throws {
        // Same as reject - delete both directions
        try await rejectRequest(from: userId)
    }
}

// MARK: - Friendship DTOs
struct SupabaseFriendshipFull: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let friendUserId: UUID
    let status: String
    let isIncoming: Bool
    let createdAt: Date
    let acceptedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case status
        case isIncoming = "is_incoming"
        case createdAt = "created_at"
        case acceptedAt = "accepted_at"
    }
}

struct SupabaseFriendshipInsert: Codable {
    let userId: UUID
    let friendUserId: UUID
    let status: String
    let isIncoming: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case status
        case isIncoming = "is_incoming"
    }
}
