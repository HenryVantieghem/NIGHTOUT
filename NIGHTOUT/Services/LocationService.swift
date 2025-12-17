import Foundation
import Supabase
import CoreLocation

/// Service for real-time friend locations and location sharing
final class LocationService: @unchecked Sendable {
    static let shared = LocationService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Friend Locations

    /// Update current user's location (upsert to friend_locations)
    /// - Parameters:
    ///   - latitude: Current latitude
    ///   - longitude: Current longitude
    ///   - accuracy: Location accuracy in meters
    ///   - nightId: Optional active night ID
    ///   - venueName: Optional current venue name
    func updateMyLocation(
        latitude: Double,
        longitude: Double,
        accuracy: Double? = nil,
        nightId: UUID? = nil,
        venueName: String? = nil
    ) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let location = FriendLocationInsert(
            userId: userId,
            nightId: nightId,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
            venueName: venueName
        )

        try await client
            .from("friend_locations")
            .upsert(location, onConflict: "user_id")
            .execute()
    }

    /// Get all friend locations (for live map)
    /// - Returns: Array of friend locations
    func getFriendLocations() async throws -> [FriendLocation] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Get friend IDs from friendships
        let friendships: [FriendshipRecord] = try await client
            .from("friendships")
            .select("friend_user_id")
            .eq("user_id", value: userId)
            .eq("status", value: "accepted")
            .execute()
            .value

        let friendIds = friendships.map { $0.friendUserId }

        guard !friendIds.isEmpty else { return [] }

        // Get locations for friends who are sharing
        let locations: [FriendLocation] = try await client
            .from("friend_locations")
            .select()
            .in("user_id", values: friendIds)
            .execute()
            .value

        return locations
    }

    /// Remove current user's location (stop sharing)
    func removeMyLocation() async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("friend_locations")
            .delete()
            .eq("user_id", value: userId)
            .execute()
    }

    // MARK: - Location Points (Night Route Tracking)

    /// Save a location point for route tracking
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    ///   - altitude: Optional altitude
    ///   - speed: Optional speed in m/s
    ///   - timestamp: Point timestamp
    func saveLocationPoint(
        nightId: UUID,
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        speed: Double? = nil,
        timestamp: Date = Date()
    ) async throws {
        guard let client else { throw ServiceError.notConfigured }

        let point = LocationPointInsert(
            nightId: nightId,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speed: speed,
            timestamp: timestamp
        )

        try await client
            .from("location_points")
            .insert(point)
            .execute()
    }

    /// Save multiple location points (batch insert)
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - coordinates: Array of CLLocationCoordinate2D
    func saveLocationPoints(nightId: UUID, coordinates: [CLLocationCoordinate2D]) async throws {
        guard let client else { throw ServiceError.notConfigured }

        let points = coordinates.map { coord in
            LocationPointInsert(
                nightId: nightId,
                latitude: coord.latitude,
                longitude: coord.longitude,
                altitude: nil,
                speed: nil,
                timestamp: Date()
            )
        }

        guard !points.isEmpty else { return }

        try await client
            .from("location_points")
            .insert(points)
            .execute()
    }

    /// Get location points for a night (for route display)
    /// - Parameter nightId: Night ID
    /// - Returns: Array of location points ordered by timestamp
    func getLocationPoints(nightId: UUID) async throws -> [LocationPoint] {
        guard let client else { throw ServiceError.notConfigured }

        let points: [LocationPoint] = try await client
            .from("location_points")
            .select()
            .eq("night_id", value: nightId)
            .order("timestamp", ascending: true)
            .execute()
            .value

        return points
    }

    // MARK: - Location Sharing Settings

    /// Get current user's location sharing settings
    /// - Returns: Location sharing settings or nil if not set
    func getLocationSettings() async throws -> LocationSharingSettings? {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let settings: [LocationSharingSettings] = try await client
            .from("location_sharing_settings")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return settings.first
    }

    /// Update location sharing settings
    /// - Parameter settings: New settings to save
    func updateLocationSettings(_ settings: LocationSharingSettingsUpdate) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Upsert settings
        let fullSettings = LocationSharingSettingsInsert(
            userId: userId,
            sharingMode: settings.sharingMode,
            defaultVisibility: settings.defaultVisibility,
            shareWithCloseFriends: settings.shareWithCloseFriends
        )

        try await client
            .from("location_sharing_settings")
            .upsert(fullSettings, onConflict: "user_id")
            .execute()
    }

    // MARK: - Location Sharing Friends (Specific Friend Permissions)

    /// Get list of friends with specific location sharing permissions
    /// - Returns: Array of friend sharing records
    func getLocationSharingFriends() async throws -> [LocationSharingFriend] {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let friends: [LocationSharingFriend] = try await client
            .from("location_sharing_friends")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return friends
    }

    /// Update location sharing permission for a specific friend
    /// - Parameters:
    ///   - friendId: Friend's user ID
    ///   - canSeeLocation: Whether friend can see location
    func updateFriendLocationPermission(friendId: UUID, canSeeLocation: Bool) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let record = LocationSharingFriendInsert(
            userId: userId,
            friendUserId: friendId,
            canSeeLocation: canSeeLocation
        )

        try await client
            .from("location_sharing_friends")
            .upsert(record, onConflict: "user_id,friend_user_id")
            .execute()
    }

    /// Remove location sharing permission for a friend
    /// - Parameter friendId: Friend's user ID
    func removeFriendLocationPermission(friendId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("location_sharing_friends")
            .delete()
            .eq("user_id", value: userId)
            .eq("friend_user_id", value: friendId)
            .execute()
    }
}

// MARK: - DTOs

private struct FriendLocationInsert: Encodable, Sendable {
    let userId: UUID
    let nightId: UUID?
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let venueName: String?
    let lastUpdated: Date

    init(
        userId: UUID,
        nightId: UUID?,
        latitude: Double,
        longitude: Double,
        accuracy: Double?,
        venueName: String?
    ) {
        self.userId = userId
        self.nightId = nightId
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.venueName = venueName
        self.lastUpdated = Date()
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nightId = "night_id"
        case latitude
        case longitude
        case accuracy
        case venueName = "venue_name"
        case lastUpdated = "last_updated"
    }
}

private struct FriendshipRecord: Decodable {
    let friendUserId: UUID

    enum CodingKeys: String, CodingKey {
        case friendUserId = "friend_user_id"
    }
}

private struct LocationPointInsert: Encodable, Sendable {
    let nightId: UUID
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case latitude
        case longitude
        case altitude
        case speed
        case timestamp
    }
}

struct LocationPoint: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let speed: Double?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case latitude
        case longitude
        case altitude
        case speed
        case timestamp
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationSharingSettings: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let sharingMode: String
    let defaultVisibility: String
    let shareWithCloseFriends: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sharingMode = "sharing_mode"
        case defaultVisibility = "default_visibility"
        case shareWithCloseFriends = "share_with_close_friends"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var mode: SharingMode {
        SharingMode(rawValue: sharingMode) ?? .duringNight
    }

    var visibility: Visibility {
        Visibility(rawValue: defaultVisibility) ?? .friends
    }

    enum SharingMode: String, CaseIterable, Sendable {
        case always = "always"
        case duringNight = "during_night"
        case manual = "manual"
        case never = "never"
    }

    enum Visibility: String, CaseIterable, Sendable {
        case everyone = "everyone"
        case friends = "friends"
        case closeFriends = "close_friends"
        case nobody = "nobody"
    }
}

struct LocationSharingSettingsUpdate: Sendable {
    let sharingMode: String
    let defaultVisibility: String
    let shareWithCloseFriends: Bool
}

private struct LocationSharingSettingsInsert: Encodable, Sendable {
    let userId: UUID
    let sharingMode: String
    let defaultVisibility: String
    let shareWithCloseFriends: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case sharingMode = "sharing_mode"
        case defaultVisibility = "default_visibility"
        case shareWithCloseFriends = "share_with_close_friends"
    }
}

struct LocationSharingFriend: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let friendUserId: UUID
    let canSeeLocation: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case canSeeLocation = "can_see_location"
        case createdAt = "created_at"
    }
}

private struct LocationSharingFriendInsert: Encodable, Sendable {
    let userId: UUID
    let friendUserId: UUID
    let canSeeLocation: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case friendUserId = "friend_user_id"
        case canSeeLocation = "can_see_location"
    }
}
