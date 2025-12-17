import Foundation
import SwiftData

/// Comment on a night model matching Supabase `comments` table
@Model
final class Comment {
    @Attribute(.unique) var id: UUID
    var nightId: UUID
    var authorId: UUID

    // Content
    var text: String

    // Timestamps
    var timestamp: Date
    var editedAt: Date?

    // Relationships
    var night: Night?

    init(
        id: UUID = UUID(),
        nightId: UUID,
        authorId: UUID,
        text: String,
        timestamp: Date = Date(),
        editedAt: Date? = nil
    ) {
        self.id = id
        self.nightId = nightId
        self.authorId = authorId
        self.text = text
        self.timestamp = timestamp
        self.editedAt = editedAt
    }
}

// MARK: - Computed Properties
extension Comment {
    var isEdited: Bool {
        editedAt != nil
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
