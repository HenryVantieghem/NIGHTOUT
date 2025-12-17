import Foundation
import Supabase
import UIKit

/// Service for media upload and management
final class MediaService: @unchecked Sendable {
    static let shared = MediaService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private let bucket = "media"

    private init() {}

    // MARK: - Upload

    /// Upload photo for a night
    func uploadPhoto(
        nightId: UUID,
        image: UIImage,
        latitude: Double? = nil,
        longitude: Double? = nil,
        caption: String? = nil
    ) async throws -> String {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MediaError.compressionFailed
        }

        // Generate unique path
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "\(userId)/\(nightId)/\(timestamp).jpg"

        // Upload to storage
        try await client.storage
            .from(bucket)
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg"))

        // Create media record
        let mediaInsert = SupabaseMediaInsert(
            nightId: nightId,
            type: "photo",
            storagePath: path,
            latitude: latitude,
            longitude: longitude,
            caption: caption
        )

        try await client
            .from("media")
            .insert(mediaInsert)
            .execute()

        return path
    }

    /// Upload avatar image
    func uploadAvatar(userId: UUID, image: UIImage) async throws -> String {
        guard let client else { throw ServiceError.notConfigured }

        // Compress and resize for avatar
        let resized = resizeImage(image, targetSize: CGSize(width: 400, height: 400))
        guard let imageData = resized.jpegData(compressionQuality: 0.9) else {
            throw MediaError.compressionFailed
        }

        // Use fixed path for avatar (overwrites existing)
        let path = "avatars/\(userId).jpg"

        try await client.storage
            .from(bucket)
            .upload(path, data: imageData, options: .init(contentType: "image/jpeg", upsert: true))

        // Return public URL
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }

    // MARK: - Fetch

    /// Get media for a night
    func getMedia(nightId: UUID) async throws -> [SupabaseMedia] {
        guard let client else { throw ServiceError.notConfigured }

        let response: [SupabaseMedia] = try await client
            .from("media")
            .select()
            .eq("night_id", value: nightId)
            .order("captured_at", ascending: true)
            .execute()
            .value

        return response
    }

    /// Get public URL for media
    func getPublicURL(path: String) throws -> URL {
        guard let client else { throw ServiceError.notConfigured }
        return try client.storage.from(bucket).getPublicURL(path: path)
    }

    // MARK: - Delete

    /// Delete media
    func deleteMedia(id: UUID, storagePath: String) async throws {
        guard let client else { throw ServiceError.notConfigured }

        // Delete from storage
        try await client.storage
            .from(bucket)
            .remove(paths: [storagePath])

        // Delete record
        try await client
            .from("media")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Helpers

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? image
    }
}

// MARK: - Media Errors
enum MediaError: LocalizedError {
    case compressionFailed
    case uploadFailed
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .uploadFailed:
            return "Failed to upload media"
        case .invalidFormat:
            return "Invalid media format"
        }
    }
}

// MARK: - Media DTOs
struct SupabaseMedia: Codable, Identifiable {
    let id: UUID
    let nightId: UUID
    let type: String
    let storagePath: String
    let thumbnailPath: String?
    let capturedAt: Date
    let latitude: Double?
    let longitude: Double?
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case type
        case storagePath = "storage_path"
        case thumbnailPath = "thumbnail_path"
        case capturedAt = "captured_at"
        case latitude
        case longitude
        case caption
    }
}

struct SupabaseMediaInsert: Codable {
    let nightId: UUID
    let type: String
    let storagePath: String
    let latitude: Double?
    let longitude: Double?
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case type
        case storagePath = "storage_path"
        case latitude
        case longitude
        case caption
    }
}
