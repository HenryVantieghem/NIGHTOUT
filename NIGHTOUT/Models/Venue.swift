import Foundation
import SwiftData
import CoreLocation

/// Venue/location check-in model matching Supabase `venues` table
@Model
final class Venue {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Venue details
    var name: String
    var address: String?

    // Location
    var latitude: Double
    var longitude: Double

    // Timing
    var arrivedAt: Date
    var leftAt: Date?

    // Metadata
    var placeId: String? // Google/Apple Maps place ID

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        name: String,
        address: String? = nil,
        latitude: Double,
        longitude: Double,
        arrivedAt: Date = Date(),
        leftAt: Date? = nil,
        placeId: String? = nil
    ) {
        self.id = id
        self.nightId = nightId
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.arrivedAt = arrivedAt
        self.leftAt = leftAt
        self.placeId = placeId
    }
}

// MARK: - Computed Properties
extension Venue {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var duration: TimeInterval? {
        guard let leftAt else { return nil }
        return leftAt.timeIntervalSince(arrivedAt)
    }

    var formattedDuration: String? {
        guard let duration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var isCurrentVenue: Bool {
        leftAt == nil
    }
}
