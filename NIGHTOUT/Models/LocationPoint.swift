import Foundation
import SwiftData
import CoreLocation

/// GPS location point for route tracking matching Supabase `location_points` table
@Model
final class LocationPoint {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Location
    var latitude: Double
    var longitude: Double
    var altitude: Double?

    // Accuracy
    var accuracy: Double
    var speed: Double?
    var course: Double?

    // Timing
    var timestamp: Date

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        accuracy: Double = 0,
        speed: Double? = nil,
        course: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.nightId = nightId
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.speed = speed
        self.course = course
        self.timestamp = timestamp
    }
}

// MARK: - Convenience Initializer
extension LocationPoint {
    convenience init(nightId: UUID, location: CLLocation) {
        self.init(
            nightId: nightId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            accuracy: location.horizontalAccuracy,
            speed: location.speed >= 0 ? location.speed : nil,
            course: location.course >= 0 ? location.course : nil,
            timestamp: location.timestamp
        )
    }
}

// MARK: - Computed Properties
extension LocationPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            course: course ?? -1,
            speed: speed ?? -1,
            timestamp: timestamp
        )
    }

    /// Distance to another location point in meters
    func distance(to other: LocationPoint) -> Double {
        clLocation.distance(from: other.clLocation)
    }
}
