import Foundation
import SwiftData

/// Night out session model matching Supabase `nights` table
@Model
final class Night {
    @Attribute(.unique) var id: UUID
    var userId: UUID

    // Content
    var title: String?
    var caption: String?

    // Timing
    var startTime: Date
    var endTime: Date?
    var duration: Int // in seconds

    // Status
    var isActive: Bool
    var isPublic: Bool

    // Visibility settings
    var visibility: NightVisibility
    var liveVisibility: LiveVisibility

    // Location
    var startLatitude: Double?
    var startLongitude: Double?
    var currentLatitude: Double?
    var currentLongitude: Double?
    var currentVenueName: String?
    var distance: Double // in meters

    // Route
    var routePolyline: String?

    // Social
    var likeCount: Int

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    var user: User?

    @Relationship(deleteRule: .cascade, inverse: \Drink.night)
    var drinks: [Drink]?

    @Relationship(deleteRule: .cascade, inverse: \Venue.night)
    var venues: [Venue]?

    @Relationship(deleteRule: .cascade, inverse: \Media.night)
    var media: [Media]?

    @Relationship(deleteRule: .cascade, inverse: \MoodEntry.night)
    var moodEntries: [MoodEntry]?

    @Relationship(deleteRule: .cascade, inverse: \LocationPoint.night)
    var locationPoints: [LocationPoint]?

    @Relationship(deleteRule: .cascade, inverse: \LiveUpdate.night)
    var liveUpdates: [LiveUpdate]?

    @Relationship(deleteRule: .cascade, inverse: \Comment.night)
    var comments: [Comment]?

    @Relationship(deleteRule: .cascade, inverse: \Song.night)
    var songs: [Song]?

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String? = nil,
        caption: String? = nil,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: Int = 0,
        isActive: Bool = true,
        isPublic: Bool = true,
        visibility: NightVisibility = .friends,
        liveVisibility: LiveVisibility = .friends,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        currentLatitude: Double? = nil,
        currentLongitude: Double? = nil,
        currentVenueName: String? = nil,
        distance: Double = 0,
        routePolyline: String? = nil,
        likeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.caption = caption
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.isActive = isActive
        self.isPublic = isPublic
        self.visibility = visibility
        self.liveVisibility = liveVisibility
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
        self.currentVenueName = currentVenueName
        self.distance = distance
        self.routePolyline = routePolyline
        self.likeCount = likeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Enums
enum NightVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"

    var displayName: String {
        switch self {
        case .public: return "Everyone"
        case .friends: return "Friends Only"
        case .private: return "Only Me"
        }
    }

    var icon: String {
        switch self {
        case .public: return "globe"
        case .friends: return "person.2"
        case .private: return "lock"
        }
    }
}

enum LiveVisibility: String, Codable, CaseIterable {
    case everyone = "everyone"
    case friends = "friends"
    case nobody = "nobody"

    var displayName: String {
        switch self {
        case .everyone: return "Everyone"
        case .friends: return "Friends Only"
        case .nobody: return "Nobody"
        }
    }
}

// MARK: - Computed Properties
extension Night {
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }

    var drinkCount: Int {
        drinks?.count ?? 0
    }

    var venueCount: Int {
        venues?.count ?? 0
    }

    var photoCount: Int {
        media?.filter { $0.type == .photo }.count ?? 0
    }
}
