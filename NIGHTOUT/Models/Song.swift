import Foundation
import SwiftData

/// Song played during night model matching Supabase `songs` table
@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Song details
    var title: String
    var artist: String
    var albumName: String?
    var artworkUrl: String?

    // External IDs
    var appleMusicId: String?
    var spotifyId: String?

    // Timing
    var timestamp: Date

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        title: String,
        artist: String,
        albumName: String? = nil,
        artworkUrl: String? = nil,
        appleMusicId: String? = nil,
        spotifyId: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.nightId = nightId
        self.title = title
        self.artist = artist
        self.albumName = albumName
        self.artworkUrl = artworkUrl
        self.appleMusicId = appleMusicId
        self.spotifyId = spotifyId
        self.timestamp = timestamp
    }
}

// MARK: - Computed Properties
extension Song {
    var artworkURL: URL? {
        guard let artworkUrl else { return nil }
        return URL(string: artworkUrl)
    }

    var displayTitle: String {
        "\(title) - \(artist)"
    }

    var appleMusicURL: URL? {
        guard let appleMusicId else { return nil }
        return URL(string: "https://music.apple.com/song/\(appleMusicId)")
    }

    var spotifyURL: URL? {
        guard let spotifyId else { return nil }
        return URL(string: "https://open.spotify.com/track/\(spotifyId)")
    }
}
