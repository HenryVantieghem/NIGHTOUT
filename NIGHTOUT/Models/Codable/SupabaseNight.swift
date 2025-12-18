import Foundation

/// Codable DTO matching Supabase `nights` table
struct SupabaseNight: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID

    // Content
    var title: String?
    var caption: String?

    // Timing
    let startTime: Date
    var endTime: Date?
    var duration: Int

    // Status
    var isActive: Bool
    var isPublic: Bool

    // Visibility
    var visibility: String
    var liveVisibility: String

    // Location
    var startLatitude: Double?
    var startLongitude: Double?
    var currentLatitude: Double?
    var currentLongitude: Double?
    var currentVenueName: String?
    var distance: Double

    // Route
    var routePolyline: String?

    // Social
    var likeCount: Int

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case caption
        case startTime = "start_time"
        case endTime = "end_time"
        case duration
        case isActive = "is_active"
        case isPublic = "is_public"
        case visibility
        case liveVisibility = "live_visibility"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case currentLatitude = "current_latitude"
        case currentLongitude = "current_longitude"
        case currentVenueName = "current_venue_name"
        case distance
        case routePolyline = "route_polyline"
        case likeCount = "like_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion to SwiftData Model
extension SupabaseNight {
    func toModel() -> Night {
        Night(
            id: id,
            userId: userId,
            title: title,
            caption: caption,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            isActive: isActive,
            isPublic: isPublic,
            visibility: NightVisibility(rawValue: visibility) ?? .friends,
            liveVisibility: LiveVisibility(rawValue: liveVisibility) ?? .friends,
            startLatitude: startLatitude,
            startLongitude: startLongitude,
            currentLatitude: currentLatitude,
            currentLongitude: currentLongitude,
            currentVenueName: currentVenueName,
            distance: distance,
            routePolyline: routePolyline,
            likeCount: likeCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Create from SwiftData Model
extension SupabaseNight {
    init(from night: Night) {
        self.id = night.id
        self.userId = night.userId
        self.title = night.title
        self.caption = night.caption
        self.startTime = night.startTime
        self.endTime = night.endTime
        self.duration = night.duration
        self.isActive = night.isActive
        self.isPublic = night.isPublic
        self.visibility = night.visibility.rawValue
        self.liveVisibility = night.liveVisibility.rawValue
        self.startLatitude = night.startLatitude
        self.startLongitude = night.startLongitude
        self.currentLatitude = night.currentLatitude
        self.currentLongitude = night.currentLongitude
        self.currentVenueName = night.currentVenueName
        self.distance = night.distance
        self.routePolyline = night.routePolyline
        self.likeCount = night.likeCount
        self.createdAt = night.createdAt
        self.updatedAt = night.updatedAt
    }
}

// MARK: - Insert/Update DTOs
struct SupabaseNightInsert: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let startTime: Date
    let isActive: Bool
    var startLatitude: Double?
    var startLongitude: Double?
    let visibility: String
    let liveVisibility: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case startTime = "start_time"
        case isActive = "is_active"
        case startLatitude = "start_latitude"
        case startLongitude = "start_longitude"
        case visibility
        case liveVisibility = "live_visibility"
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        startTime: Date = Date(),
        isActive: Bool = true,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        visibility: NightVisibility = .friends,
        liveVisibility: LiveVisibility = .friends
    ) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.isActive = isActive
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.visibility = visibility.rawValue
        self.liveVisibility = liveVisibility.rawValue
    }
}

struct SupabaseNightUpdate: Codable, Sendable {
    var title: String?
    var caption: String?
    var endTime: Date?
    var duration: Int?
    var isActive: Bool?
    var isPublic: Bool?
    var currentLatitude: Double?
    var currentLongitude: Double?
    var currentVenueName: String?
    var distance: Double?
    var routePolyline: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case title
        case caption
        case endTime = "end_time"
        case duration
        case isActive = "is_active"
        case isPublic = "is_public"
        case currentLatitude = "current_latitude"
        case currentLongitude = "current_longitude"
        case currentVenueName = "current_venue_name"
        case distance
        case routePolyline = "route_polyline"
        case updatedAt = "updated_at"
    }

    init(
        title: String? = nil,
        caption: String? = nil,
        endTime: Date? = nil,
        duration: Int? = nil,
        isActive: Bool? = nil,
        isPublic: Bool? = nil,
        currentLatitude: Double? = nil,
        currentLongitude: Double? = nil,
        currentVenueName: String? = nil,
        distance: Double? = nil,
        routePolyline: String? = nil
    ) {
        self.title = title
        self.caption = caption
        self.endTime = endTime
        self.duration = duration
        self.isActive = isActive
        self.isPublic = isPublic
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
        self.currentVenueName = currentVenueName
        self.distance = distance
        self.routePolyline = routePolyline
        self.updatedAt = Date()
    }
}
