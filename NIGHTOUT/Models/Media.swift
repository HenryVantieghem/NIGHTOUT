import Foundation
import SwiftData

/// Media (photo/video) model matching Supabase `media` table
@Model
final class Media {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Media details
    var type: MediaType
    var storagePath: String
    var thumbnailPath: String?

    // Metadata
    var capturedAt: Date
    var latitude: Double?
    var longitude: Double?
    var caption: String?

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        type: MediaType,
        storagePath: String,
        thumbnailPath: String? = nil,
        capturedAt: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil,
        caption: String? = nil
    ) {
        self.id = id
        self.nightId = nightId
        self.type = type
        self.storagePath = storagePath
        self.thumbnailPath = thumbnailPath
        self.capturedAt = capturedAt
        self.latitude = latitude
        self.longitude = longitude
        self.caption = caption
    }
}

// MARK: - Media Type
enum MediaType: String, Codable {
    case photo = "photo"
    case video = "video"

    var icon: String {
        switch self {
        case .photo: return "photo"
        case .video: return "video"
        }
    }
}

// MARK: - URL Construction
extension Media {
    func imageURL(supabaseURL: String) -> URL? {
        URL(string: "\(supabaseURL)/storage/v1/object/public/media/\(storagePath)")
    }

    func thumbnailURL(supabaseURL: String) -> URL? {
        guard let thumbnailPath else { return nil }
        return URL(string: "\(supabaseURL)/storage/v1/object/public/media/\(thumbnailPath)")
    }
}
