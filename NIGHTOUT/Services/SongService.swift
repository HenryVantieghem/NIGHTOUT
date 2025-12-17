import Foundation
import Supabase

/// Service for song/music history during nights
final class SongService: @unchecked Sendable {
    static let shared = SongService()

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Songs

    /// Save a song to the night's music history
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - title: Song title
    ///   - artist: Artist name
    ///   - album: Optional album name
    ///   - artworkUrl: Optional album artwork URL
    ///   - appleMusicId: Optional Apple Music ID for linking
    ///   - spotifyId: Optional Spotify ID for linking
    /// - Returns: Created song record
    @discardableResult
    func saveSong(
        nightId: UUID,
        title: String,
        artist: String,
        album: String? = nil,
        artworkUrl: String? = nil,
        appleMusicId: String? = nil,
        spotifyId: String? = nil
    ) async throws -> Song {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let song = SongInsert(
            nightId: nightId,
            userId: userId,
            title: title,
            artist: artist,
            album: album,
            artworkUrl: artworkUrl,
            appleMusicId: appleMusicId,
            spotifyId: spotifyId
        )

        let response: [Song] = try await client
            .from("songs")
            .insert(song)
            .select()
            .execute()
            .value

        guard let created = response.first else {
            throw ServiceError.invalidData
        }

        return created
    }

    /// Get all songs for a night
    /// - Parameter nightId: Night ID
    /// - Returns: Array of songs ordered by when they were played
    func getSongs(nightId: UUID) async throws -> [Song] {
        guard let client else { throw ServiceError.notConfigured }

        let songs: [Song] = try await client
            .from("songs")
            .select()
            .eq("night_id", value: nightId)
            .order("played_at", ascending: true)
            .execute()
            .value

        return songs
    }

    /// Get unique songs (no duplicates by title + artist)
    /// - Parameter nightId: Night ID
    /// - Returns: Array of unique songs
    func getUniqueSongs(nightId: UUID) async throws -> [Song] {
        let allSongs = try await getSongs(nightId: nightId)

        var seen: Set<String> = []
        var unique: [Song] = []

        for song in allSongs {
            let key = "\(song.title.lowercased())|\(song.artist.lowercased())"
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(song)
            }
        }

        return unique
    }

    /// Get recent songs for a night
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - limit: Maximum number of songs
    /// - Returns: Array of recent songs (newest first)
    func getRecentSongs(nightId: UUID, limit: Int = 5) async throws -> [Song] {
        guard let client else { throw ServiceError.notConfigured }

        let songs: [Song] = try await client
            .from("songs")
            .select()
            .eq("night_id", value: nightId)
            .order("played_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return songs
    }

    /// Delete a song
    /// - Parameter id: Song ID
    func deleteSong(id: UUID) async throws {
        guard let client else { throw ServiceError.notConfigured }

        try await client
            .from("songs")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Get music stats for user
    /// - Returns: User's music statistics
    func getMusicStats() async throws -> MusicStats {
        guard let client else { throw ServiceError.notConfigured }
        guard let userId = SessionManager.shared.currentUser?.id else {
            throw ServiceError.unauthorized
        }

        let songs: [Song] = try await client
            .from("songs")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        guard !songs.isEmpty else {
            return MusicStats(
                totalSongs: 0,
                uniqueSongs: 0,
                topArtist: nil,
                topSong: nil,
                artistCounts: [:]
            )
        }

        // Calculate unique songs
        var songKeys: Set<String> = []
        for song in songs {
            songKeys.insert("\(song.title.lowercased())|\(song.artist.lowercased())")
        }

        // Calculate artist counts
        var artistCounts: [String: Int] = [:]
        for song in songs {
            artistCounts[song.artist, default: 0] += 1
        }

        // Calculate song play counts
        var songCounts: [String: (song: Song, count: Int)] = [:]
        for song in songs {
            let key = "\(song.title.lowercased())|\(song.artist.lowercased())"
            if var existing = songCounts[key] {
                existing.count += 1
                songCounts[key] = existing
            } else {
                songCounts[key] = (song: song, count: 1)
            }
        }

        let topArtist = artistCounts.max(by: { $0.value < $1.value })?.key
        let topSong = songCounts.max(by: { $0.value.count < $1.value.count })?.value.song

        return MusicStats(
            totalSongs: songs.count,
            uniqueSongs: songKeys.count,
            topArtist: topArtist,
            topSong: topSong,
            artistCounts: artistCounts
        )
    }

    /// Get top artists for a specific night
    /// - Parameters:
    ///   - nightId: Night ID
    ///   - limit: Maximum number of artists
    /// - Returns: Array of (artist, playCount) tuples
    func getTopArtists(nightId: UUID, limit: Int = 5) async throws -> [(artist: String, count: Int)] {
        let songs = try await getSongs(nightId: nightId)

        var artistCounts: [String: Int] = [:]
        for song in songs {
            artistCounts[song.artist, default: 0] += 1
        }

        return artistCounts
            .map { (artist: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - DTOs

private struct SongInsert: Encodable, Sendable {
    let nightId: UUID
    let userId: UUID
    let title: String
    let artist: String
    let album: String?
    let artworkUrl: String?
    let appleMusicId: String?
    let spotifyId: String?

    enum CodingKeys: String, CodingKey {
        case nightId = "night_id"
        case userId = "user_id"
        case title
        case artist
        case album
        case artworkUrl = "artwork_url"
        case appleMusicId = "apple_music_id"
        case spotifyId = "spotify_id"
    }
}

struct Song: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let userId: UUID
    let title: String
    let artist: String
    let album: String?
    let artworkUrl: String?
    let appleMusicId: String?
    let spotifyId: String?
    let playedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case userId = "user_id"
        case title
        case artist
        case album
        case artworkUrl = "artwork_url"
        case appleMusicId = "apple_music_id"
        case spotifyId = "spotify_id"
        case playedAt = "played_at"
    }

    /// Display string (Title - Artist)
    var displayName: String {
        "\(title) - \(artist)"
    }

    /// Apple Music URL if ID exists
    var appleMusicUrl: URL? {
        guard let appleMusicId else { return nil }
        return URL(string: "https://music.apple.com/song/\(appleMusicId)")
    }

    /// Spotify URL if ID exists
    var spotifyUrl: URL? {
        guard let spotifyId else { return nil }
        return URL(string: "https://open.spotify.com/track/\(spotifyId)")
    }
}

struct MusicStats: Sendable {
    let totalSongs: Int
    let uniqueSongs: Int
    let topArtist: String?
    let topSong: Song?
    let artistCounts: [String: Int]

    /// Top 5 artists by play count
    var topArtists: [(artist: String, count: Int)] {
        artistCounts
            .map { (artist: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }
}
