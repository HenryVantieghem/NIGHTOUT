import Foundation
import SwiftData

/// Friendship/friend request model matching Supabase `friendships` table
@Model
final class Friendship {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var friendUserId: UUID

    // Status
    var status: FriendshipStatus
    var isIncoming: Bool

    // Timestamps
    var createdAt: Date
    var acceptedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        friendUserId: UUID,
        status: FriendshipStatus = .pending,
        isIncoming: Bool = false,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.friendUserId = friendUserId
        self.status = status
        self.isIncoming = isIncoming
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
    }
}

// MARK: - Friendship Status
enum FriendshipStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case blocked = "blocked"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Friends"
        case .rejected: return "Rejected"
        case .blocked: return "Blocked"
        }
    }
}

// MARK: - Computed Properties
extension Friendship {
    var isPending: Bool {
        status == .pending
    }

    var isAccepted: Bool {
        status == .accepted
    }

    var isBlocked: Bool {
        status == .blocked
    }

    /// The other user's ID (not the current user)
    func otherUserId(currentUserId: UUID) -> UUID {
        userId == currentUserId ? friendUserId : userId
    }
}
