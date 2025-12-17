import Foundation
import Supabase

/// Service for mood tracking during nights
final class MoodService: @unchecked Sendable {
    static let shared = MoodService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Mood Entries

    /// Save a mood entry
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - level: Mood level (1-5)
    ///   - note: Optional note about the mood
    func saveMood(nightId: UUID, level: Int, note: String? = nil) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let entry = MoodEntryInsert(
            nightId: nightId,
            userId: userId,
            moodLevel: max(1, min(5, level)), // Clamp between 1-5
            note: note
        )

        try await client
            .from("mood_entries")
            .insert(entry)
            .execute()
    }

    /// Get all mood entries for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Array of mood entries ordered by timestamp
    func getMoods(nightId: UUID) async throws -> [MoodEntry] {
        guard let client else { throw ServiceError.notConfigured }

        let entries: [MoodEntry] = try await client
            .from("mood_entries")
            .select()
            .eq("night_id", value: nightId)
            .order("created_at", ascending: true)
            .execute()
            .value

        return entries
    }

    /// Get average mood for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Average mood level (1.0-5.0)
    func getAverageMood(nightId: UUID) async throws -> Double? {
        let moods = try await getMoods(nightId: nightId)

        guard !moods.isEmpty else { return nil }

        let sum = moods.reduce(0) { $0 + $1.moodLevel }
        return Double(sum) / Double(moods.count)
    }

    /// Get mood trend for a night (first, peak, and last mood)
    /// - Parameter nightId: Night ID
    /// - Returns: Mood trend tuple
    func getMoodTrend(nightId: UUID) async throws -> MoodTrend? {
        let moods = try await getMoods(nightId: nightId)

        guard let first = moods.first,
              let last = moods.last else { return nil }

        let peak = moods.max(by: { $0.moodLevel < $1.moodLevel })

        return MoodTrend(
            first: first,
            peak: peak,
            last: last,
            average: moods.map { $0.moodLevel }.reduce(0, +) / moods.count,
            count: moods.count
        )
    }

    /// Delete a mood entry
    /// - Parameter id: Mood entry ID
    func deleteMood(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard SessionManager.shared.currentUser?.id != nil else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("mood_entries")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Get mood stats for user
    /// - Returns: User's mood statistics
    func getMoodStats() async throws -> MoodStats {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let entries: [MoodEntry] = try await client
            .from("mood_entries")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        guard !entries.isEmpty else {
            return MoodStats(
                totalEntries: 0,
                averageMood: 0,
                moodDistribution: [:],
                mostCommonMood: nil
            )
        }

        // Calculate distribution
        var distribution: [Int: Int] = [:]
        for entry in entries {
            distribution[entry.moodLevel, default: 0] += 1
        }

        let average = Double(entries.reduce(0) { $0 + $1.moodLevel }) / Double(entries.count)
        let mostCommon = distribution.max(by: { $0.value < $1.value })?.key

        return MoodStats(
            totalEntries: entries.count,
            averageMood: average,
            moodDistribution: distribution,
            mostCommonMood: mostCommon
        )
    }
}

// MARK: - DTOs

private struct MoodEntryInsert: Encodable, Sendable {
    let nightId: UUID
    let userId: UUID
    let moodLevel: Int
    let note: String?

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
        case moodLevel = "mood_level"
        case note
    }
}

struct MoodEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let moodLevel: Int
    let note: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case moodLevel = "mood_level"
        case note
        case createdAt = "created_at"
    }

    /// Mood level as emoji
    var emoji: String {
        switch moodLevel {
        case 1: return "😴"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😄"
        case 5: return "🤩"
        default: return "😐"
        }
    }

    /// Mood level as description
    var description: String {
        switch moodLevel {
        case 1: return "Tired"
        case 2: return "Okay"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Amazing"
        default: return "Unknown"
        }
    }
}

struct MoodTrend: Sendable {
    let first: MoodEntry
    let peak: MoodEntry?
    let last: MoodEntry
    let average: Int
    let count: Int

    var isImproving: Bool {
        last.moodLevel > first.moodLevel
    }

    var isDeclining: Bool {
        last.moodLevel < first.moodLevel
    }

    var isStable: Bool {
        last.moodLevel == first.moodLevel
    }
}

struct MoodStats: Sendable {
    let totalEntries: Int
    let averageMood: Double
    let moodDistribution: [Int: Int]
    let mostCommonMood: Int?

    var averageEmoji: String {
        let rounded = Int(averageMood.rounded())
        switch rounded {
        case 1: return "😴"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😄"
        case 5: return "🤩"
        default: return "😐"
        }
    }
}
