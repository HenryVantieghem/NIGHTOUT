import Foundation
import Supabase

/// Service for user profile operations
final class UserService: @unchecked Sendable {
    static let shared = UserService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Fetch

    /// Get current user's profile
    func getCurrentProfile() async throws -> SupabaseProfile? {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else { return nil }

        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        return response.first
    }

    /// Get profile by user ID
    func getProfile(userId: UUID) async throws -> SupabaseProfile? {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        return response.first
    }

    /// Get profile by username
    func getProfile(username: String) async throws -> SupabaseProfile? {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("username", value: username)
            .execute()
            .value

        return response.first
    }

    /// Search profiles by username or display name
    func searchProfiles(query: String, limit: Int = 20) async throws -> [SupabaseProfile] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .or("username.ilike.%\(query)%,display_name.ilike.%\(query)%")
            .limit(limit)
            .execute()
            .value

        return response
    }

    // MARK: - Update

    /// Update current user's profile
    func updateProfile(update: SupabaseProfileUpdate) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        try await client
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
    }

    /// Update username
    func updateUsername(_ username: String) async throws {
        let update = SupabaseProfileUpdate(username: username)
        try await updateProfile(update: update)
    }

    /// Update display name
    func updateDisplayName(_ displayName: String) async throws {
        let update = SupabaseProfileUpdate(displayName: displayName)
        try await updateProfile(update: update)
    }

    /// Update bio
    func updateBio(_ bio: String?) async throws {
        let update = SupabaseProfileUpdate(bio: bio)
        try await updateProfile(update: update)
    }

    /// Update avatar URL
    func updateAvatarUrl(_ avatarUrl: String?) async throws {
        let update = SupabaseProfileUpdate(avatarUrl: avatarUrl)
        try await updateProfile(update: update)
    }

    /// Update email notifications setting
    func updateEmailNotifications(_ enabled: Bool) async throws {
        let update = SupabaseProfileUpdate(emailNotifications: enabled)
        try await updateProfile(update: update)
    }

    // MARK: - Stats

    /// Increment user stats after a night
    func incrementStats(
        nights: Int = 0,
        duration: Int = 0,
        distance: Double = 0,
        drinks: Int = 0,
        photos: Int = 0
    ) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Fetch current stats
        guard let profile = try await getProfile(userId: userId) else {
            throw ServiceError.notFound
        }

        // Update with incremented values
        let updateData: [String: AnyEncodable] = [
            "total_nights": AnyEncodable(profile.totalNights + nights),
            "total_duration": AnyEncodable(profile.totalDuration + duration),
            "total_distance": AnyEncodable(profile.totalDistance + distance),
            "total_drinks": AnyEncodable(profile.totalDrinks + drinks),
            "total_photos": AnyEncodable(profile.totalPhotos + photos),
            "updated_at": AnyEncodable(Date())
        ]

        try await client
            .from("profiles")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Validation

    /// Check if username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select("id")
            .eq("username", value: username)
            .execute()
            .value

        return response.isEmpty
    }
}

// MARK: - AnyEncodable Helper
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Service Errors
enum ServiceError: LocalizedError {
    case notConfigured
    case unauthorized
    case notFound
    case invalidData
    case networkError
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Service is not configured"
        case .unauthorized:
            return "You must be signed in to perform this action"
        case .notFound:
            return "The requested resource was not found"
        case .invalidData:
            return "Invalid data received"
        case .networkError:
            return "Network error. Please check your connection"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
