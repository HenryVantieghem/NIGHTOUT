import Foundation
import SwiftData
import Supabase

/// Service for syncing local SwiftData with Supabase
final class SyncService: @unchecked Sendable {
    static let shared = SyncService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Sync Profiles

    /// Sync profile from Supabase to local SwiftData
    @MainActor
    func syncProfile(context: ModelContext) async throws {
        guard let profile = try await UserService.shared.getCurrentProfile() else {
            return
        }

        // Check if user exists locally
        let userId = profile.id
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userId })
        let existing = try context.fetch(descriptor)

        if let localUser = existing.first {
            // Update existing
            updateLocalUser(localUser, from: profile)
        } else {
            // Insert new
            let newUser = profile.toModel()
            context.insert(newUser)
        }

        try context.save()
    }

    @MainActor
    private func updateLocalUser(_ user: User, from profile: SupabaseProfile) {
        user.username = profile.username
        user.displayName = profile.displayName
        user.bio = profile.bio
        user.avatarUrl = profile.avatarUrl
        user.email = profile.email
        user.totalNights = profile.totalNights
        user.totalDuration = profile.totalDuration
        user.totalDistance = profile.totalDistance
        user.totalDrinks = profile.totalDrinks
        user.totalPhotos = profile.totalPhotos
        user.currentStreak = profile.currentStreak
        user.longestStreak = profile.longestStreak
        user.emailNotifications = profile.emailNotifications
        user.updatedAt = profile.updatedAt
    }

    // MARK: - Sync Nights

    /// Sync nights from Supabase to local SwiftData
    @MainActor
    func syncNights(context: ModelContext, limit: Int = 50) async throws {
        let remoteNights = try await NightService.shared.getMyNights(limit: limit)

        for remoteNight in remoteNights {
            let nightId = remoteNight.id
            let descriptor = FetchDescriptor<Night>(predicate: #Predicate { $0.id == nightId })
            let existing = try context.fetch(descriptor)

            if let localNight = existing.first {
                // Update existing
                updateLocalNight(localNight, from: remoteNight)
            } else {
                // Insert new
                let newNight = remoteNight.toModel()
                context.insert(newNight)
            }
        }

        try context.save()
    }

    @MainActor
    private func updateLocalNight(_ night: Night, from remote: SupabaseNight) {
        night.title = remote.title
        night.caption = remote.caption
        night.endTime = remote.endTime
        night.duration = remote.duration
        night.isActive = remote.isActive
        night.isPublic = remote.isPublic
        night.visibility = NightVisibility(rawValue: remote.visibility) ?? .friends
        night.liveVisibility = LiveVisibility(rawValue: remote.liveVisibility) ?? .friends
        night.currentLatitude = remote.currentLatitude
        night.currentLongitude = remote.currentLongitude
        night.currentVenueName = remote.currentVenueName
        night.distance = remote.distance
        night.routePolyline = remote.routePolyline
        night.likeCount = remote.likeCount
        night.updatedAt = remote.updatedAt
    }

    // MARK: - Full Sync

    /// Perform full sync of all data
    @MainActor
    func performFullSync(context: ModelContext) async throws {
        try await syncProfile(context: context)
        try await syncNights(context: context)
    }

    // MARK: - Clear Local Data

    /// Clear all local SwiftData (for logout)
    @MainActor
    func clearLocalData(context: ModelContext) throws {
        // Delete all models
        try context.delete(model: User.self)
        try context.delete(model: Night.self)
        try context.delete(model: Drink.self)
        try context.delete(model: Venue.self)
        try context.delete(model: Media.self)
        try context.delete(model: MoodEntry.self)
        try context.delete(model: Achievement.self)
        try context.delete(model: Friendship.self)
        try context.delete(model: LocationPoint.self)
        try context.delete(model: CustomDrinkTemplate.self)
        try context.delete(model: LiveUpdate.self)
        try context.delete(model: Comment.self)
        try context.delete(model: Song.self)

        try context.save()
    }
}
