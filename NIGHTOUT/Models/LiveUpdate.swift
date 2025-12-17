import Foundation
import SwiftData

/// Live activity/update model matching Supabase `live_updates` table
@Model
final class LiveUpdate {
    @Attribute(.unique) var id: UUID
    var nightId: UUID

    // Update type
    var type: LiveUpdateType
    var timestamp: Date

    // Content (varies by type)
    var mediaData: String? // Storage path for media
    var drinkType: String?
    var venueName: String?
    var moodEmoji: String?
    var milestoneText: String?
    var songTitle: String?
    var songArtist: String?
    var caption: String?

    // Location (optional)
    var latitude: Double?
    var longitude: Double?

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        type: LiveUpdateType,
        timestamp: Date = Date(),
        mediaData: String? = nil,
        drinkType: String? = nil,
        venueName: String? = nil,
        moodEmoji: String? = nil,
        milestoneText: String? = nil,
        songTitle: String? = nil,
        songArtist: String? = nil,
        caption: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.nightId = nightId
        self.type = type
        self.timestamp = timestamp
        self.mediaData = mediaData
        self.drinkType = drinkType
        self.venueName = venueName
        self.moodEmoji = moodEmoji
        self.milestoneText = milestoneText
        self.songTitle = songTitle
        self.songArtist = songArtist
        self.caption = caption
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Live Update Type
enum LiveUpdateType: String, Codable {
    case nightStarted = "night_started"
    case drinkAdded = "drink_added"
    case venueArrived = "venue_arrived"
    case venueLeft = "venue_left"
    case photoAdded = "photo_added"
    case moodUpdate = "mood_update"
    case milestone = "milestone"
    case songPlaying = "song_playing"
    case nightEnded = "night_ended"

    var icon: String {
        switch self {
        case .nightStarted: return "play.circle"
        case .drinkAdded: return "cup.and.saucer"
        case .venueArrived: return "mappin.circle"
        case .venueLeft: return "arrow.right.circle"
        case .photoAdded: return "camera"
        case .moodUpdate: return "face.smiling"
        case .milestone: return "star"
        case .songPlaying: return "music.note"
        case .nightEnded: return "moon.zzz"
        }
    }

    var displayName: String {
        switch self {
        case .nightStarted: return "Night Started"
        case .drinkAdded: return "Had a drink"
        case .venueArrived: return "Arrived at"
        case .venueLeft: return "Left"
        case .photoAdded: return "Captured a moment"
        case .moodUpdate: return "Feeling"
        case .milestone: return "Milestone"
        case .songPlaying: return "Listening to"
        case .nightEnded: return "Night Ended"
        }
    }
}

// MARK: - Computed Properties
extension LiveUpdate {
    var displayText: String {
        switch type {
        case .nightStarted:
            return "Started the night"
        case .drinkAdded:
            return "Had a \(drinkType ?? "drink")"
        case .venueArrived:
            return "Arrived at \(venueName ?? "a venue")"
        case .venueLeft:
            return "Left \(venueName ?? "the venue")"
        case .photoAdded:
            return caption ?? "Captured a moment"
        case .moodUpdate:
            return "Feeling \(moodEmoji ?? "😊")"
        case .milestone:
            return milestoneText ?? "Reached a milestone"
        case .songPlaying:
            if let title = songTitle, let artist = songArtist {
                return "\(title) by \(artist)"
            }
            return songTitle ?? "Listening to music"
        case .nightEnded:
            return "Ended the night"
        }
    }
}
