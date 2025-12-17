import Foundation
import Supabase
import Realtime

/// Central manager for all Supabase real-time subscriptions
/// Handles friend locations, live updates, reactions, and comments
@Observable
final class SupabaseRealtimeManager: @unchecked Sendable {
    static let shared = SupabaseRealtimeManager()

    // MARK: - Published State

    /// Live friend locations for map view
    private(set) var friendLocations: [FriendLocation] = []

    /// Live updates for active night timeline
    private(set) var liveUpdates: [RealtimeLiveUpdate] = []

    /// Current subscriptions
    private var friendLocationChannel: RealtimeChannelV2?
    private var liveUpdatesChannel: RealtimeChannelV2?
    private var reactionsChannel: RealtimeChannelV2?
    private var commentsChannel: RealtimeChannelV2?

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    private init() {}

    // MARK: - Friend Locations Subscription

    /// Subscribe to real-time friend location updates
    /// - Parameter userId: Current user's ID to filter friends
    func subscribeFriendLocations(for userId: UUID) async {
        guard let client else {
            print("⚠️ Supabase client not configured")
            return
        }

        // Unsubscribe from existing channel if any
        await unsubscribeFriendLocations()

        let channel = client.realtimeV2.channel("friend_locations_\(userId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "friend_locations"
        )

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "friend_locations"
        )

        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "friend_locations"
        )

        await channel.subscribe()

        friendLocationChannel = channel

        // Handle insertions
        Task {
            for await insertion in insertions {
                await handleFriendLocationInsert(insertion)
            }
        }

        // Handle updates
        Task {
            for await update in updates {
                await handleFriendLocationUpdate(update)
            }
        }

        // Handle deletions
        Task {
            for await deletion in deletions {
                await handleFriendLocationDelete(deletion)
            }
        }

        print("✅ Subscribed to friend locations")
    }

    /// Unsubscribe from friend location updates
    func unsubscribeFriendLocations() async {
        if let channel = friendLocationChannel {
            await channel.unsubscribe()
            friendLocationChannel = nil
            print("🔴 Unsubscribed from friend locations")
        }
    }

    private func handleFriendLocationInsert(_ action: InsertAction) async {
        do {
            let location = try action.decodeRecord(as: FriendLocation.self, decoder: JSONDecoder.supabaseDecoder)
            await MainActor.run {
                self.friendLocations.append(location)
            }
        } catch {
            print("❌ Failed to decode friend location insert: \(error)")
        }
    }

    private func handleFriendLocationUpdate(_ action: UpdateAction) async {
        do {
            let location = try action.decodeRecord(as: FriendLocation.self, decoder: JSONDecoder.supabaseDecoder)
            await MainActor.run {
                if let index = self.friendLocations.firstIndex(where: { $0.userId == location.userId }) {
                    self.friendLocations[index] = location
                }
            }
        } catch {
            print("❌ Failed to decode friend location update: \(error)")
        }
    }

    private func handleFriendLocationDelete(_ action: DeleteAction) async {
        do {
            let oldRecord = try action.decodeOldRecord(as: FriendLocation.self, decoder: JSONDecoder.supabaseDecoder)
            await MainActor.run {
                self.friendLocations.removeAll { $0.userId == oldRecord.userId }
            }
        } catch {
            print("❌ Failed to decode friend location delete: \(error)")
        }
    }

    // MARK: - Live Updates Subscription

    /// Subscribe to real-time live updates for a specific night
    /// - Parameter nightId: Night ID to subscribe to
    func subscribeLiveUpdates(for nightId: UUID) async {
        guard let client else {
            print("⚠️ Supabase client not configured")
            return
        }

        // Unsubscribe from existing channel if any
        await unsubscribeLiveUpdates()

        let channel = client.realtimeV2.channel("live_updates_\(nightId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "live_updates",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        await channel.subscribe()

        liveUpdatesChannel = channel

        // Handle insertions
        Task {
            for await insertion in insertions {
                await handleLiveUpdateInsert(insertion)
            }
        }

        print("✅ Subscribed to live updates for night: \(nightId)")
    }

    /// Unsubscribe from live updates
    func unsubscribeLiveUpdates() async {
        if let channel = liveUpdatesChannel {
            await channel.unsubscribe()
            liveUpdatesChannel = nil
            await MainActor.run {
                self.liveUpdates.removeAll()
            }
            print("🔴 Unsubscribed from live updates")
        }
    }

    private func handleLiveUpdateInsert(_ action: InsertAction) async {
        do {
            let update = try action.decodeRecord(as: RealtimeLiveUpdate.self, decoder: JSONDecoder.supabaseDecoder)
            await MainActor.run {
                self.liveUpdates.insert(update, at: 0)
            }
        } catch {
            print("❌ Failed to decode live update: \(error)")
        }
    }

    // MARK: - Reactions Subscription

    /// Callback type for reaction changes
    typealias ReactionCallback = @Sendable (ReactionChange) -> Void

    enum ReactionChange: Sendable {
        case added(SupabaseReaction)
        case removed(SupabaseReaction)
    }

    /// Subscribe to real-time reactions for a specific night
    /// - Parameters:
    ///   - nightId: Night ID to subscribe to
    ///   - callback: Callback for reaction changes
    func subscribeReactions(for nightId: UUID, callback: @escaping ReactionCallback) async {
        guard let client else {
            print("⚠️ Supabase client not configured")
            return
        }

        // Unsubscribe from existing channel if any
        await unsubscribeReactions()

        let channel = client.realtimeV2.channel("reactions_\(nightId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "reactions",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "reactions",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        await channel.subscribe()

        reactionsChannel = channel

        // Handle insertions
        Task {
            for await insertion in insertions {
                do {
                    let reaction = try insertion.decodeRecord(as: SupabaseReaction.self, decoder: JSONDecoder.supabaseDecoder)
                    callback(.added(reaction))
                } catch {
                    print("❌ Failed to decode reaction insert: \(error)")
                }
            }
        }

        // Handle deletions
        Task {
            for await deletion in deletions {
                do {
                    let reaction = try deletion.decodeOldRecord(as: SupabaseReaction.self, decoder: JSONDecoder.supabaseDecoder)
                    callback(.removed(reaction))
                } catch {
                    print("❌ Failed to decode reaction delete: \(error)")
                }
            }
        }

        print("✅ Subscribed to reactions for night: \(nightId)")
    }

    /// Unsubscribe from reactions
    func unsubscribeReactions() async {
        if let channel = reactionsChannel {
            await channel.unsubscribe()
            reactionsChannel = nil
            print("🔴 Unsubscribed from reactions")
        }
    }

    // MARK: - Comments Subscription

    /// Callback type for comment changes
    typealias CommentCallback = @Sendable (CommentChange) -> Void

    enum CommentChange: Sendable {
        case added(SupabaseComment)
        case updated(SupabaseComment)
        case removed(UUID)
    }

    /// Subscribe to real-time comments for a specific night
    /// - Parameters:
    ///   - nightId: Night ID to subscribe to
    ///   - callback: Callback for comment changes
    func subscribeComments(for nightId: UUID, callback: @escaping CommentCallback) async {
        guard let client else {
            print("⚠️ Supabase client not configured")
            return
        }

        // Unsubscribe from existing channel if any
        await unsubscribeComments()

        let channel = client.realtimeV2.channel("comments_\(nightId.uuidString)")

        let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "comments",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        let updates = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "comments",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        let deletions = channel.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "comments",
            filter: .eq("night_id", value: nightId.uuidString)
        )

        await channel.subscribe()

        commentsChannel = channel

        // Handle insertions
        Task {
            for await insertion in insertions {
                do {
                    let comment = try insertion.decodeRecord(as: SupabaseComment.self, decoder: JSONDecoder.supabaseDecoder)
                    callback(.added(comment))
                } catch {
                    print("❌ Failed to decode comment insert: \(error)")
                }
            }
        }

        // Handle updates
        Task {
            for await update in updates {
                do {
                    let comment = try update.decodeRecord(as: SupabaseComment.self, decoder: JSONDecoder.supabaseDecoder)
                    callback(.updated(comment))
                } catch {
                    print("❌ Failed to decode comment update: \(error)")
                }
            }
        }

        // Handle deletions
        Task {
            for await deletion in deletions {
                do {
                    let oldRecord = try deletion.decodeOldRecord(as: SupabaseComment.self, decoder: JSONDecoder.supabaseDecoder)
                    callback(.removed(oldRecord.id))
                } catch {
                    print("❌ Failed to decode comment delete: \(error)")
                }
            }
        }

        print("✅ Subscribed to comments for night: \(nightId)")
    }

    /// Unsubscribe from comments
    func unsubscribeComments() async {
        if let channel = commentsChannel {
            await channel.unsubscribe()
            commentsChannel = nil
            print("🔴 Unsubscribed from comments")
        }
    }

    // MARK: - Cleanup

    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        await unsubscribeFriendLocations()
        await unsubscribeLiveUpdates()
        await unsubscribeReactions()
        await unsubscribeComments()
        print("🔴 Unsubscribed from all real-time channels")
    }
}

// MARK: - Supporting Types

/// Friend location for live map
struct FriendLocation: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let userId: UUID
    let nightId: UUID?
    let latitude: Double
    let longitude: Double
    let accuracy: Double?
    let venueName: String?
    let lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case nightId = "night_id"
        case latitude
        case longitude
        case accuracy
        case venueName = "venue_name"
        case lastUpdated = "last_updated"
    }
}

/// Live update for activity timeline (real-time)
struct RealtimeLiveUpdate: Codable, Identifiable, Sendable {
    let id: UUID
    let nightId: UUID
    let updateType: String
    let content: String?
    let mediaUrl: String?
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case nightId = "night_id"
        case updateType = "update_type"
        case content
        case mediaUrl = "media_url"
        case latitude
        case longitude
        case createdAt = "created_at"
    }

    /// Update type enumeration
    var type: UpdateType {
        UpdateType(rawValue: updateType) ?? .status
    }

    enum UpdateType: String, Sendable {
        case status = "status"
        case photo = "photo"
        case video = "video"
        case drink = "drink"
        case mood = "mood"
        case venue = "venue"
        case song = "song"
    }
}

// MARK: - JSON Decoder Extension

extension JSONDecoder {
    /// Supabase-compatible decoder with ISO8601 date handling
    static let supabaseDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try with fractional seconds first
            if let date = formatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }

        return decoder
    }()
}
