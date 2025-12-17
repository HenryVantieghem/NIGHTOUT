import Foundation
import Supabase

/// Service for night out operations
final class NightService: @unchecked Sendable {
    static let shared = NightService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get night by ID
    func getNight(id: UUID) async throws -> SupabaseNight? {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .eq("id", value: id)
            .execute()
            .value

        return response.first
    }

    /// Get user's nights
    func getNights(userId: UUID, limit: Int = 50) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .eq("user_id", value: userId)
            .order("start_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    /// Get current user's nights
    func getMyNights(limit: Int = 50) async throws -> [SupabaseNight] {
        guard client != nil else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        return try await getNights(userId: userId, limit: limit)
    }

    /// Get active night for user
    func getActiveNight(userId: UUID) async throws -> SupabaseNight? {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value

        return response.first
    }

    /// Get combined feed (user's nights + friends' nights)
    func getFeed(userId: UUID, limit: Int = 50) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        // Get friend IDs first
        let friendships: [SupabaseFriendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "accepted")
            .execute()
            .value

        let friendIds = friendships.map { $0.friendUserId }

        // Include user's own ID for combined feed
        var allUserIds = friendIds
        allUserIds.append(userId)

        // Get all public/completed nights from user and friends
        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .in("user_id", values: allUserIds)
            .eq("is_active", value: false)
            .order("start_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    /// Get only friends' nights (following filter)
    func getFriendsFeed(userId: UUID, limit: Int = 50) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        // Get friend IDs
        let friendships: [SupabaseFriendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "accepted")
            .execute()
            .value

        let friendIds = friendships.map { $0.friendUserId }

        guard !friendIds.isEmpty else { return [] }

        // Get friends' public nights only
        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .in("user_id", values: friendIds)
            .eq("is_public", value: true)
            .eq("is_active", value: false)
            .order("start_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    /// Get highlighted/popular nights (high like count)
    func getHighlights(limit: Int = 20) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        // Get public nights sorted by like count
        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .eq("is_public", value: true)
            .eq("is_active", value: false)
            .gt("like_count", value: 0)
            .order("like_count", ascending: false)
            .order("start_time", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    /// Get live friends (friends with active nights)
    func getLiveFriends(userId: UUID) async throws -> [SupabaseNight] {
        guard let client else { throw ServiceError.notConfigured }

        // Get friend IDs
        let friendships: [SupabaseFriendship] = try await client
            .from("friendships")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "accepted")
            .execute()
            .value

        let friendIds = friendships.map { $0.friendUserId }

        guard !friendIds.isEmpty else { return [] }

        // Get active nights where live visibility allows
        let response: [SupabaseNight] = try await client
            .from("nights")
            .select()
            .in("user_id", values: friendIds)
            .eq("is_active", value: true)
            .neq("live_visibility", value: "nobody")
            .execute()
            .value

        return response
    }

    // MARK: - Create

    /// Start a new night
    func startNight(
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        visibility: NightVisibility = .friends,
        liveVisibility: LiveVisibility = .friends
    ) async throws -> SupabaseNight {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let insert = SupabaseNightInsert(
            userId: userId,
            startLatitude: startLatitude,
            startLongitude: startLongitude,
            visibility: visibility,
            liveVisibility: liveVisibility
        )

        let response: [SupabaseNight] = try await client
            .from("nights")
            .insert(insert)
            .select()
            .execute()
            .value

        guard let night = response.first else {
            throw ServiceError.invalidData
        }

        return night
    }

    // MARK: - Update

    /// Update night
    func updateNight(id: UUID, update: SupabaseNightUpdate) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("nights")
            .update(update)
            .eq("id", value: id)
            .execute()
    }

    /// End a night
    func endNight(
        id: UUID,
        title: String?,
        caption: String?,
        duration: Int,
        distance: Double,
        routePolyline: String?
    ) async throws {
        let update = SupabaseNightUpdate(
            title: title,
            caption: caption,
            endTime: Date(),
            duration: duration,
            isActive: false,
            distance: distance,
            routePolyline: routePolyline
        )

        try await updateNight(id: id, update: update)
    }

    /// Update current location
    func updateLocation(
        nightId: UUID,
        latitude: Double,
        longitude: Double,
        venueName: String?
    ) async throws {
        let update = SupabaseNightUpdate(
            currentLatitude: latitude,
            currentLongitude: longitude,
            currentVenueName: venueName
        )

        try await updateNight(id: nightId, update: update)
    }

    // MARK: - Delete

    /// Delete a night
    func deleteNight(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("nights")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Friendship DTO for fetching
private struct SupabaseFriendship: Codable {
    let id: UUID
    let userId: UUID
    let friendUserId: UUID
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case status
    }
}
