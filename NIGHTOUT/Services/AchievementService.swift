import Foundation
import Supabase

/// Service for achievement tracking and unlocking
final class AchievementService: @unchecked Sendable {
    static let shared = AchievementService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get user's achievements
    func getAchievements(userId: UUID) async throws -> [SupabaseAchievement] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseAchievement] = try await client
            .from("achievements")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response
    }

    /// Get current user's achievements
    func getMyAchievements() async throws -> [SupabaseAchievement] {
        guard client != nil else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        return try await getAchievements(userId: userId)
    }

    /// Check if user has specific achievement
    func hasAchievement(type: AchievementType, userId: UUID) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseAchievement] = try await client
            .from("achievements")
            .select()
            .eq("user_id", value: userId)
            .eq("type", value: type.rawValue)
            .execute()
            .value

        return !response.isEmpty
    }

    // MARK: - Unlock

    /// Unlock an achievement for current user
    func unlockAchievement(type: AchievementType) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Check if already unlocked
        if try await hasAchievement(type: type, userId: userId) {
            return false
        }

        // Create achievement
        let achievement = SupabaseAchievementInsert(
            userId: userId,
            type: type.rawValue,
            progress: type.targetProgress
        )

        try await client
            .from("achievements")
            .insert(achievement)
            .execute()

        return true
    }

    /// Update achievement progress
    func updateProgress(type: AchievementType, progress: Int) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Check if already exists
        let existing: [SupabaseAchievement] = try await client
            .from("achievements")
            .select()
            .eq("user_id", value: userId)
            .eq("type", value: type.rawValue)
            .execute()
            .value

        if let achievement = existing.first {
            // Update existing
            try await client
                .from("achievements")
                .update(["progress": progress])
                .eq("id", value: achievement.id)
                .execute()

            // Check if newly completed
            return progress >= type.targetProgress && achievement.progress < type.targetProgress
        } else {
            // Create new with progress
            let achievement = SupabaseAchievementInsert(
                userId: userId,
                type: type.rawValue,
                progress: progress
            )

            try await client
                .from("achievements")
                .insert(achievement)
                .execute()

            // Check if completed
            return progress >= type.targetProgress
        }
    }

    // MARK: - Check & Award

    /// Check and award achievements after a night ends
    func checkAndAwardAchievements(profile: SupabaseProfile) async throws -> [AchievementType] {
        var unlocked: [AchievementType] = []

        // Night milestones
        if profile.totalNights >= 1 {
            if try await unlockAchievement(type: .firstNight) {
                unlocked.append(.firstNight)
            }
        }
        if profile.totalNights >= 10 {
            if try await unlockAchievement(type: .tenNights) {
                unlocked.append(.tenNights)
            }
        }
        if profile.totalNights >= 50 {
            if try await unlockAchievement(type: .fiftyNights) {
                unlocked.append(.fiftyNights)
            }
        }
        if profile.totalNights >= 100 {
            if try await unlockAchievement(type: .hundredNights) {
                unlocked.append(.hundredNights)
            }
        }

        // Photo achievements
        if profile.totalPhotos >= 100 {
            if try await unlockAchievement(type: .photoGenic) {
                unlocked.append(.photoGenic)
            }
        }

        // Streak achievements
        if profile.currentStreak >= 7 {
            if try await unlockAchievement(type: .weekStreak) {
                unlocked.append(.weekStreak)
            }
        }
        if profile.currentStreak >= 30 {
            if try await unlockAchievement(type: .monthStreak) {
                unlocked.append(.monthStreak)
            }
        }

        return unlocked
    }
}

// MARK: - Achievement DTOs
struct SupabaseAchievement: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let type: String
    let unlockedAt: Date
    let progress: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case unlockedAt = "unlocked_at"
        case progress
    }

    var achievementType: AchievementType? {
        AchievementType(rawValue: type)
    }
}

struct SupabaseAchievementInsert: Codable {
    let userId: UUID
    let type: String
    let progress: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case type
        case progress
    }
}
