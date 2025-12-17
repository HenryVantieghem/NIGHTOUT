import Foundation
import SwiftData

/// Mood tracking entry model matching Supabase `mood_entries` table
@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Mood details
    var level: Int // 1-5 scale
    var timestamp: Date

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        level: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.nightId = nightId
        self.level = min(5, max(1, level)) // Clamp to 1-5
        self.timestamp = timestamp
    }
}

// MARK: - Mood Level
extension MoodEntry {
    @MainActor
    var moodLevel: MoodLevel {
        MoodLevel(rawValue: level) ?? .neutral
    }

    @MainActor
    var emoji: String {
        moodLevel.emoji
    }

    @MainActor
    var displayName: String {
        moodLevel.displayName
    }
}

enum MoodLevel: Int, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case amazing = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😕"
        case .neutral: return "😐"
        case .good: return "😊"
        case .amazing: return "🤩"
        }
    }

    var displayName: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Not Great"
        case .neutral: return "Okay"
        case .good: return "Good"
        case .amazing: return "Amazing"
        }
    }
}
