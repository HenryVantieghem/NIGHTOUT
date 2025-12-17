import Foundation
import UIKit
import CoreLocation
import AVFoundation
import Photos
import UserNotifications

/// Manages all app permissions with modern async/await patterns
final class PermissionsManager: @unchecked Sendable {
    static let shared = PermissionsManager()

    private let locationManager = CLLocationManager()

    private init() {}

    // MARK: - Location Permission

    enum LocationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    var locationStatus: LocationStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestLocationPermission() async -> Bool {
        guard locationStatus == .notDetermined else {
            return locationStatus == .authorized
        }

        return await withCheckedContinuation { continuation in
            let delegate = LocationPermissionDelegate { status in
                continuation.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
            }
            // Keep delegate alive
            objc_setAssociatedObject(self.locationManager, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            self.locationManager.delegate = delegate
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Camera Permission

    enum CameraStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    var cameraStatus: CameraStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestCameraPermission() async -> Bool {
        guard cameraStatus == .notDetermined else {
            return cameraStatus == .authorized
        }

        return await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Photo Library Permission

    enum PhotosStatus {
        case notDetermined
        case authorized
        case limited
        case denied
        case restricted
    }

    var photosStatus: PhotosStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }

    func requestPhotosPermission() async -> Bool {
        guard photosStatus == .notDetermined else {
            return photosStatus == .authorized || photosStatus == .limited
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }

    // MARK: - Notifications Permission

    enum NotificationsStatus {
        case notDetermined
        case authorized
        case denied
        case provisional
    }

    func notificationsStatus() async -> NotificationsStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .provisional:
            return .provisional
        case .ephemeral:
            return .authorized
        @unknown default:
            return .denied
        }
    }

    func requestNotificationsPermission() async -> Bool {
        let status = await notificationsStatus()
        guard status == .notDetermined else {
            return status == .authorized || status == .provisional
        }

        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notifications permission error: \(error)")
            return false
        }
    }

    // MARK: - Open Settings

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    }
}

// MARK: - Location Permission Delegate
private class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {
    private let completion: (CLAuthorizationStatus) -> Void

    init(completion: @escaping (CLAuthorizationStatus) -> Void) {
        self.completion = completion
        super.init()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined {
            completion(manager.authorizationStatus)
        }
    }
}
