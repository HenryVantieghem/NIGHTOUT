import Foundation
import Supabase

/// Service for live activity updates during nights
final class LiveUpdateService: @unchecked Sendable {
    static let shared = LiveUpdateService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Live Updates

    /// Post a live update
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - type: Update type
    ///   - content: Optional text content
    ///   - mediaUrl: Optional media URL
    ///   - latitude: Optional latitude
    ///   - longitude: Optional longitude
    /// - Returns: Created live update
    @discardableResult
    func postUpdate(
        nightId: UUID,
        type: ServiceUpdateType,
        content: String? = nil,
        mediaUrl: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) async throws -> LiveUpdateRecord {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let update = LiveUpdateInsert(
            nightId: nightId,
            userId: userId,
            updateType: type.rawValue,
            content: content,
            mediaUrl: mediaUrl,
            latitude: latitude,
            longitude: longitude
        )

        let response: [LiveUpdateRecord] = try await client
            .from("live_updates")
            .insert(update)
            .select()
            .execute()
            .value

        guard let created = response.first else {
            throw ServiceError.invalidData
        }

        return created
    }

    /// Post a status update
    func postStatus(nightId: UUID, status: String) async throws {
        try await postUpdate(nightId: nightId, type: .status, content: status)
    }

    /// Post a photo update
    func postPhoto(nightId: UUID, mediaUrl: String, caption: String? = nil) async throws {
        try await postUpdate(nightId: nightId, type: .photo, content: caption, mediaUrl: mediaUrl)
    }

    /// Post a video update
    func postVideo(nightId: UUID, mediaUrl: String, caption: String? = nil) async throws {
        try await postUpdate(nightId: nightId, type: .video, content: caption, mediaUrl: mediaUrl)
    }

    /// Post a drink update
    func postDrink(nightId: UUID, drinkName: String) async throws {
        try await postUpdate(nightId: nightId, type: .drink, content: drinkName)
    }

    /// Post a mood update
    func postMood(nightId: UUID, moodEmoji: String, moodText: String? = nil) async throws {
        let content = moodText.map { "\(moodEmoji) \($0)" } ?? moodEmoji
        try await postUpdate(nightId: nightId, type: .mood, content: content)
    }

    /// Post a venue check-in update
    func postVenueCheckin(nightId: UUID, venueName: String, latitude: Double, longitude: Double) async throws {
        try await postUpdate(
            nightId: nightId,
            type: .venue,
            content: venueName,
            latitude: latitude,
            longitude: longitude
        )
    }

    /// Post a song update
    func postSong(nightId: UUID, songTitle: String, artist: String) async throws {
        try await postUpdate(nightId: nightId, type: .song, content: "\(songTitle) - \(artist)")
    }

    /// Get all updates for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Array of updates ordered by timestamp (newest first)
    func getUpdates(nightId: UUID) async throws -> [LiveUpdateRecord] {
        guard let client else { throw ServiceError.notConfigured }

        let updates: [LiveUpdateRecord] = try await client
            .from("live_updates")
            .select()
            .eq("night_id", value: nightId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return updates
    }

    /// Get updates by type
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - type: Update type to filter by
    /// - Returns: Array of updates of specified type
    func getUpdates(nightId: UUID, type: ServiceUpdateType) async throws -> [LiveUpdateRecord] {
        guard let client else { throw ServiceError.notConfigured }

        let updates: [LiveUpdateRecord] = try await client
            .from("live_updates")
            .select()
            .eq("night_id", value: nightId)
            .eq("update_type", value: type.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value

        return updates
    }

    /// Get recent updates (last N)
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - limit: Maximum number of updates
    /// - Returns: Array of recent updates
    func getRecentUpdates(nightId: UUID, limit: Int = 10) async throws -> [LiveUpdateRecord] {
        guard let client else { throw ServiceError.notConfigured }

        let updates: [LiveUpdateRecord] = try await client
            .from("live_updates")
            .select()
            .eq("night_id", value: nightId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return updates
    }

    /// Delete an update
    /// - Parameter id: Update ID
    func deleteUpdate(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("live_updates")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Get update counts by type for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Dictionary of update type to count
    func getUpdateCounts(nightId: UUID) async throws -> [ServiceUpdateType: Int] {
        let updates = try await getUpdates(nightId: nightId)

        var counts: [ServiceUpdateType: Int] = [:]
        for update in updates {
            counts[update.type, default: 0] += 1
        }

        return counts
    }
}

// MARK: - Types

enum ServiceUpdateType: String, CaseIterable, Sendable, Hashable {
    case status = "status"
    case photo = "photo"
    case video = "video"
    case drink = "drink"
    case mood = "mood"
    case venue = "venue"
    case song = "song"

    var icon: String {
        switch self {
        case .status: return "text.bubble"
        case .photo: return "camera"
        case .video: return "video"
        case .drink: return "wineglass"
        case .mood: return "face.smiling"
        case .venue: return "mappin.circle"
        case .song: return "music.note"
        }
    }

    var displayName: String {
        switch self {
        case .status: return "Status"
        case .photo: return "Photo"
        case .video: return "Video"
        case .drink: return "Drink"
        case .mood: return "Mood"
        case .venue: return "Venue"
        case .song: return "Song"
        }
    }
}

// MARK: - DTOs

private struct LiveUpdateInsert: Encodable, Sendable {
    let nightId: UUID
    let userId: UUID
    let updateType: String
    let content: String?
    let mediaUrl: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
        case updateType = "update_type"
        case content
        case mediaUrl = "media_url"
        case latitude
        case longitude
    }
}

struct LiveUpdateRecord: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let updateType: String
    let content: String?
    let mediaUrl: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case updateType = "update_type"
        case content
        case mediaUrl = "media_url"
        case latitude
        case longitude
        case createdAt = "created_at"
    }

    var type: ServiceUpdateType {
        ServiceUpdateType(rawValue: updateType) ?? .status
    }

    /// Relative time string (e.g., "5m ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
