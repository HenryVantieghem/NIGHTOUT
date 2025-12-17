import Foundation
import SwiftData

/// User profile model matching Supabase `profiles` table
@Model
final class User {
    @Attribute(.unique) var id: UUID
    var username: String
    var displayName: String
    var bio: String?
    var avatarUrl: String?
    var email: String?

    // Stats
    var totalNights: Int
    var totalDuration: Int // in seconds
    var totalDistance: Double // in meters
    var totalDrinks: Int
    var totalPhotos: Int

    // Streaks
    var currentStreak: Int
    var longestStreak: Int

    // Settings
    var emailNotifications: Bool

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Night.user)
    var nights: [Night]?

    @Relationship(deleteRule: .cascade, inverse: \Achievement.user)
    var achievements: [Achievement]?

    init(
        id: UUID = UUID(),
        username: String,
        displayName: String,
        bio: String? = nil,
        avatarUrl: String? = nil,
        email: String? = nil,
        totalNights: Int = 0,
        totalDuration: Int = 0,
        totalDistance: Double = 0,
        totalDrinks: Int = 0,
        totalPhotos: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        emailNotifications: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarUrl = avatarUrl
        self.email = email
        self.totalNights = totalNights
        self.totalDuration = totalDuration
        self.totalDistance = totalDistance
        self.totalDrinks = totalDrinks
        self.totalPhotos = totalPhotos
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.emailNotifications = emailNotifications
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension User {
    var avatarURL: URL? {
        guard let avatarUrl else { return nil }
        return URL(string: avatarUrl)
    }

    var formattedTotalDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedTotalDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.1f km", totalDistance / 1000)
        }
        return String(format: "%.0f m", totalDistance)
    }
}
