import Foundation

/// Codable DTO matching Supabase `profiles` table
struct SupabaseProfile: Codable, Identifiable, Sendable {
    let id: UUID
    var username: String
    var displayName: String
    var bio: String?
    var avatarUrl: String?
    var email: String?

    // Stats
    var totalNights: Int
    var totalDuration: Int
    var totalDistance: Double
    var totalDrinks: Int
    var totalPhotos: Int

    // Streaks
    var currentStreak: Int
    var longestStreak: Int

    // Settings
    var emailNotifications: Bool

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case email
        case totalNights = "total_nights"
        case totalDuration = "total_duration"
        case totalDistance = "total_distance"
        case totalDrinks = "total_drinks"
        case totalPhotos = "total_photos"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case emailNotifications = "email_notifications"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversion to SwiftData Model
extension SupabaseProfile {
    func toModel() -> User {
        User(
            id: id,
            username: username,
            displayName: displayName,
            bio: bio,
            avatarUrl: avatarUrl,
            email: email,
            totalNights: totalNights,
            totalDuration: totalDuration,
            totalDistance: totalDistance,
            totalDrinks: totalDrinks,
            totalPhotos: totalPhotos,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            emailNotifications: emailNotifications,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Create from SwiftData Model
extension SupabaseProfile {
    init(from user: User) {
        self.id = user.id
        self.username = user.username
        self.displayName = user.displayName
        self.bio = user.bio
        self.avatarUrl = user.avatarUrl
        self.email = user.email
        self.totalNights = user.totalNights
        self.totalDuration = user.totalDuration
        self.totalDistance = user.totalDistance
        self.totalDrinks = user.totalDrinks
        self.totalPhotos = user.totalPhotos
        self.currentStreak = user.currentStreak
        self.longestStreak = user.longestStreak
        self.emailNotifications = user.emailNotifications
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

// MARK: - Insert/Update DTOs
struct SupabaseProfileInsert: Codable, Sendable {
    let id: UUID
    let username: String
    let displayName: String
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case email
    }
}

struct SupabaseProfileUpdate: Codable, Sendable {
    var username: String?
    var displayName: String?
    var bio: String?
    var avatarUrl: String?
    var emailNotifications: Bool?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case username
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case emailNotifications = "email_notifications"
        case updatedAt = "updated_at"
    }

    init(
        username: String? = nil,
        displayName: String? = nil,
        bio: String? = nil,
        avatarUrl: String? = nil,
        emailNotifications: Bool? = nil
    ) {
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.emailNotifications = emailNotifications
        self.updatedAt = Date()
    }
}
