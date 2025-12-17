import Foundation
import Supabase

/// Demo account detection utilities
enum DemoAccount {
    /// Demo account email addresses for testing
    static let demoEmails: Set<String> = [
        "demo@nightout.app",
        "test@nightout.app",
        "preview@nightout.app"
    ]

    /// Demo account user IDs
    static let demoUserIds: Set<UUID> = []

    /// Check if an email belongs to a demo account
    static func isDemoUser(email: String?) -> Bool {
        guard let email = email?.lowercased() else { return false }
        return demoEmails.contains(email)
    }

    /// Check if a user ID belongs to a demo account
    static func isDemoUser(userId: UUID?) -> Bool {
        guard let userId else { return false }
        return demoUserIds.contains(userId)
    }

    /// Check if a session belongs to a demo account
    static func isDemoUser(session: Session) -> Bool {
        // Check email from session user metadata
        if let email = session.user.email?.lowercased() {
            return demoEmails.contains(email)
        }
        // Also check user ID
        return demoUserIds.contains(session.user.id)
    }

    /// Check if current session is a demo account
    @MainActor
    static func isCurrentUserDemo() -> Bool {
        guard let email = SessionManager.shared.userEmail else { return false }
        return isDemoUser(email: email)
    }
}
