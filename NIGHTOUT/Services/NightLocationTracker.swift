//
//  NightLocationTracker.swift
//  NIGHTOUT
//
//  Real-time GPS tracking during active nights - Strava-like route collection
//

import Foundation
import CoreLocation
import Observation

/// Tracks user location during an active night, collecting GPS points for route visualization
@MainActor
@Observable
final class NightLocationTracker: NSObject {
    static let shared = NightLocationTracker()

    // MARK: - Published State
    private(set) var isTracking = false
    private(set) var currentLocation: CLLocation?
    private(set) var collectedPoints: [CLLocationCoordinate2D] = []
    private(set) var totalDistance: Double = 0 // meters
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var locationError: String?

    // MARK: - Private Properties
    private var locationManager: CLLocationManager?
    private var activeNightId: UUID?
    private var lastSavedLocation: CLLocation?
    private var saveTimer: Timer?

    // Configuration
    private let minimumDistanceForUpdate: Double = 10 // meters
    private let saveInterval: TimeInterval = 30 // seconds
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest

    // MARK: - Initialization

    override private init() {
        super.init()
    }

    // MARK: - Public Interface

    /// Start tracking location for an active night
    /// - Parameter nightId: The ID of the active night
    func startTracking(for nightId: UUID) {
        guard !isTracking else { return }

        activeNightId = nightId
        collectedPoints = []
        totalDistance = 0
        locationError = nil

        setupLocationManager()
        startSaveTimer()

        isTracking = true
        print("📍 Started location tracking for night: \(nightId)")
    }

    /// Stop tracking and return the route polyline
    /// - Returns: Encoded polyline string of the route
    func stopTracking() -> String {
        guard isTracking else { return "" }

        // Stop location updates
        locationManager?.stopUpdatingLocation()
        saveTimer?.invalidate()
        saveTimer = nil

        // Save any remaining points
        Task {
            await saveCollectedPoints()
        }

        isTracking = false

        // Encode the route as polyline
        let simplifiedPoints = PolylineEncoder.simplify(collectedPoints)
        let polyline = PolylineEncoder.encode(simplifiedPoints)

        print("📍 Stopped tracking. Collected \(collectedPoints.count) points, encoded to \(polyline.count) chars")

        // Reset state
        let result = polyline
        activeNightId = nil
        collectedPoints = []
        totalDistance = 0
        currentLocation = nil

        return result
    }

    /// Request location permission if not determined
    func requestPermission() {
        if locationManager == nil {
            setupLocationManager()
        }

        if authorizationStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
    }

    /// Check if location services are available and authorized
    var isLocationAvailable: Bool {
        CLLocationManager.locationServicesEnabled() &&
        (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }

    // MARK: - Private Methods

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = desiredAccuracy
        locationManager?.distanceFilter = minimumDistanceForUpdate
        locationManager?.allowsBackgroundLocationUpdates = false // For now, no background tracking
        locationManager?.pausesLocationUpdatesAutomatically = false

        authorizationStatus = locationManager?.authorizationStatus ?? .notDetermined

        // Request permission if needed
        if authorizationStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else if isLocationAvailable {
            locationManager?.startUpdatingLocation()
        }
    }

    private func startSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.saveCollectedPoints()
            }
        }
    }

    private func saveCollectedPoints() async {
        guard let nightId = activeNightId, !collectedPoints.isEmpty else { return }

        do {
            // Save to Supabase
            try await LocationService.shared.saveLocationPoints(nightId: nightId, coordinates: collectedPoints)

            // Also update the night's current location and distance
            if let lastPoint = collectedPoints.last, let currentLoc = currentLocation {
                try await NightService.shared.updateNightLocation(
                    nightId: nightId,
                    latitude: lastPoint.latitude,
                    longitude: lastPoint.longitude,
                    distance: totalDistance
                )

                // Update friend location for live tracking
                try await LocationService.shared.updateMyLocation(
                    latitude: lastPoint.latitude,
                    longitude: lastPoint.longitude,
                    accuracy: currentLoc.horizontalAccuracy,
                    nightId: nightId
                )
            }

            print("📍 Saved \(collectedPoints.count) location points")
        } catch {
            print("❌ Failed to save location points: \(error)")
            locationError = "Failed to save location"
        }
    }

    private func addLocationPoint(_ location: CLLocation) {
        let coordinate = location.coordinate

        // Calculate distance from last point
        if let lastLocation = lastSavedLocation {
            let distance = location.distance(from: lastLocation)
            totalDistance += distance
        }

        collectedPoints.append(coordinate)
        currentLocation = location
        lastSavedLocation = location
    }
}

// MARK: - CLLocationManagerDelegate

extension NightLocationTracker: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status

            if status == .authorizedWhenInUse || status == .authorizedAlways {
                if self.isTracking {
                    self.locationManager?.startUpdatingLocation()
                }
            } else if status == .denied || status == .restricted {
                self.locationError = "Location access denied. Enable in Settings."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Filter out inaccurate readings
        guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy < 100 else { return }

        Task { @MainActor in
            self.addLocationPoint(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied"
                case .locationUnknown:
                    self.locationError = "Unable to determine location"
                default:
                    self.locationError = "Location error: \(clError.localizedDescription)"
                }
            } else {
                self.locationError = error.localizedDescription
            }
            print("📍 Location error: \(error)")
        }
    }
}
