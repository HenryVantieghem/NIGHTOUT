import Foundation
import SwiftData

/// Achievement/badge model matching Supabase `achievements` table
@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var userId: UUID

    // Achievement details
    var type: AchievementType
    var unlockedAt: Date
    var progress: Int

    // Relationships
    var user: User?

    init(
        id: UUID = UUID(),
        userId: UUID,
        type: AchievementType,
        unlockedAt: Date = Date(),
        progress: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.unlockedAt = unlockedAt
        self.progress = progress
    }
}

// MARK: - Achievement Type
enum AchievementType: String, Codable, CaseIterable, Identifiable {
    // Night milestones
    case firstNight = "first_night"
    case tenNights = "ten_nights"
    case fiftyNights = "fifty_nights"
    case hundredNights = "hundred_nights"

    // Social
    case firstFriend = "first_friend"
    case tenFriends = "ten_friends"
    case socialButterfly = "social_butterfly"

    // Streaks
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"

    // Distance
    case marathoner = "marathoner"
    case explorer = "explorer"

    // Special
    case nightOwl = "night_owl"
    case earlyBird = "early_bird"
    case photoGenic = "photo_genic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstNight: return "First Night"
        case .tenNights: return "10 Nights"
        case .fiftyNights: return "50 Nights"
        case .hundredNights: return "Century"
        case .firstFriend: return "First Friend"
        case .tenFriends: return "Popular"
        case .socialButterfly: return "Social Butterfly"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Month Master"
        case .marathoner: return "Marathoner"
        case .explorer: return "Explorer"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .photoGenic: return "Photogenic"
        }
    }

    var description: String {
        switch self {
        case .firstNight: return "Complete your first night out"
        case .tenNights: return "Complete 10 nights out"
        case .fiftyNights: return "Complete 50 nights out"
        case .hundredNights: return "Complete 100 nights out"
        case .firstFriend: return "Add your first friend"
        case .tenFriends: return "Have 10 friends"
        case .socialButterfly: return "Have 50 friends"
        case .weekStreak: return "Go out 7 days in a row"
        case .monthStreak: return "Go out 30 days in a row"
        case .marathoner: return "Walk 42km in one night"
        case .explorer: return "Visit 100 different venues"
        case .nightOwl: return "Stay out past 4am"
        case .earlyBird: return "Start before 6pm"
        case .photoGenic: return "Take 100 photos"
        }
    }

    var icon: String {
        switch self {
        case .firstNight: return "star"
        case .tenNights: return "star.fill"
        case .fiftyNights: return "medal"
        case .hundredNights: return "crown"
        case .firstFriend: return "person.badge.plus"
        case .tenFriends: return "person.2"
        case .socialButterfly: return "person.3"
        case .weekStreak: return "flame"
        case .monthStreak: return "flame.fill"
        case .marathoner: return "figure.walk"
        case .explorer: return "map"
        case .nightOwl: return "moon.stars"
        case .earlyBird: return "sunrise"
        case .photoGenic: return "camera"
        }
    }

    var targetProgress: Int {
        switch self {
        case .firstNight: return 1
        case .tenNights: return 10
        case .fiftyNights: return 50
        case .hundredNights: return 100
        case .firstFriend: return 1
        case .tenFriends: return 10
        case .socialButterfly: return 50
        case .weekStreak: return 7
        case .monthStreak: return 30
        case .marathoner: return 42000
        case .explorer: return 100
        case .nightOwl: return 1
        case .earlyBird: return 1
        case .photoGenic: return 100
        }
    }
}
