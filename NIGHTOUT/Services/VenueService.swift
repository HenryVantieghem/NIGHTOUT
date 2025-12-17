import Foundation
import Supabase
import CoreLocation

/// Service for venue check-ins during nights
final class VenueService: @unchecked Sendable {
    static let shared = VenueService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Venue Check-ins

    /// Check in to a venue
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - name: Venue name
    ///   - latitude: Venue latitude
    ///   - longitude: Venue longitude
    ///   - address: Optional venue address
    ///   - category: Optional venue category
    /// - Returns: Created venue entry
    @discardableResult
    func checkIn(
        nightId: UUID,
        name: String,
        latitude: Double,
        longitude: Double,
        address: String? = nil,
        category: String? = nil
    ) async throws -> SupabaseVenue {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let venue = VenueInsert(
            nightId: nightId,
            userId: userId,
            name: name,
            latitude: latitude,
            longitude: longitude,
            address: address,
            category: category
        )

        let response: [SupabaseVenue] = try await client
            .from("venues")
            .insert(venue)
            .select()
            .execute()
            .value

        guard let created = response.first else {
            throw ServiceError.invalidData
        }

        return created
    }

    /// Check out from a venue
    /// - Parameter venueId: Venue entry ID
    func checkOut(venueId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("venues")
            .update(["left_at": Date()])
            .eq("id", value: venueId)
            .execute()
    }

    /// Get all venues for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Array of venues ordered by arrival time
    func getVenues(nightId: UUID) async throws -> [SupabaseVenue] {
        guard let client else { throw ServiceError.notConfigured }

        let venues: [SupabaseVenue] = try await client
            .from("venues")
            .select()
            .eq("night_id", value: nightId)
            .order("arrived_at", ascending: true)
            .execute()
            .value

        return venues
    }

    /// Get current venue (where left_at is null)
    /// - Parameter nightId: Night ID
    /// - Returns: Current venue or nil
    func getCurrentVenue(nightId: UUID) async throws -> SupabaseVenue? {
        guard let client else { throw ServiceError.notConfigured }

        let venues: [SupabaseVenue] = try await client
            .from("venues")
            .select()
            .eq("night_id", value: nightId)
            .is("left_at", value: nil)
            .order("arrived_at", ascending: false)
            .limit(1)
            .execute()
            .value

        return venues.first
    }

    /// Update venue details
    /// - Parameters:
    ///   - venueId: Venue ID
    ///   - name: New name
    ///   - rating: Optional rating (1-5)
    ///   - notes: Optional notes
    func updateVenue(venueId: UUID, name: String? = nil, rating: Int? = nil, notes: String? = nil) async throws {
        guard let client else { throw ServiceError.notConfigured }
        guard name != nil || rating != nil || notes != nil else { return }

        let update = VenueUpdate(
            name: name,
            rating: rating.map { max(1, min(5, $0)) },
            notes: notes
        )

        try await client
            .from("venues")
            .update(update)
            .eq("id", value: venueId)
            .execute()
    }

    /// Delete a venue
    /// - Parameter venueId: Venue ID
    func deleteVenue(venueId: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("venues")
            .delete()
            .eq("id", value: venueId)
            .execute()
    }

    /// Get venue statistics for user
    /// - Returns: User's venue statistics
    func getVenueStats() async throws -> VenueStats {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let venues: [SupabaseVenue] = try await client
            .from("venues")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        guard !venues.isEmpty else {
            return VenueStats(
                totalVenues: 0,
                uniqueVenues: 0,
                favoriteVenue: nil,
                averageTimeSpent: nil,
                venuesByCategory: [:]
            )
        }

        // Calculate unique venues by name
        let uniqueNames = Set(venues.map { $0.name.lowercased() })

        // Find most visited venue
        var venueVisitCounts: [String: Int] = [:]
        for venue in venues {
            let key = venue.name.lowercased()
            venueVisitCounts[key, default: 0] += 1
        }
        let favorite = venueVisitCounts.max(by: { $0.value < $1.value })

        // Calculate average time spent
        var totalSeconds: TimeInterval = 0
        var venuesWithDuration = 0
        for venue in venues {
            if let duration = venue.duration {
                totalSeconds += duration
                venuesWithDuration += 1
            }
        }
        let averageTime = venuesWithDuration > 0 ? totalSeconds / Double(venuesWithDuration) : nil

        // Group by category
        var byCategory: [String: Int] = [:]
        for venue in venues {
            let category = venue.category ?? "Other"
            byCategory[category, default: 0] += 1
        }

        return VenueStats(
            totalVenues: venues.count,
            uniqueVenues: uniqueNames.count,
            favoriteVenue: favorite?.key,
            averageTimeSpent: averageTime,
            venuesByCategory: byCategory
        )
    }
}

// MARK: - DTOs

private struct VenueInsert: Encodable, Sendable {
    let nightId: UUID
    let userId: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
        case name
        case latitude
        case longitude
        case address
        case category
    }
}

private struct VenueUpdate: Encodable, Sendable {
    let name: String?
    let rating: Int?
    let notes: String?
}

struct SupabaseVenue: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let category: String?
    let arrivedAt: Date
    let leftAt: Date?
    let rating: Int?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case name
        case latitude
        case longitude
        case address
        case category
        case arrivedAt = "arrived_at"
        case leftAt = "left_at"
        case rating
        case notes
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Duration at venue in seconds
    var duration: TimeInterval? {
        guard let leftAt else { return nil }
        return leftAt.timeIntervalSince(arrivedAt)
    }

    /// Formatted duration string
    var durationFormatted: String? {
        guard let duration else { return nil }

        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// Category icon
    var categoryIcon: String {
        switch category?.lowercased() {
        case "bar": return "wineglass"
        case "club": return "music.note.house"
        case "restaurant": return "fork.knife"
        case "lounge": return "sofa"
        case "pub": return "mug"
        case "rooftop": return "building.2"
        case "beach": return "beach.umbrella"
        default: return "mappin.circle"
        }
    }
}

struct VenueStats: Sendable {
    let totalVenues: Int
    let uniqueVenues: Int
    let favoriteVenue: String?
    let averageTimeSpent: TimeInterval?
    let venuesByCategory: [String: Int]

    var averageTimeFormatted: String? {
        guard let averageTimeSpent else { return nil }

        let hours = Int(averageTimeSpent) / 3600
        let minutes = (Int(averageTimeSpent) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}
