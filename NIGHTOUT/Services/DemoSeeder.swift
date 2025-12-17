import Foundation
import SwiftData

/// Seeds demo data for testing and preview purposes
final class DemoSeeder: @unchecked Sendable {
    static let shared = DemoSeeder()

    private var hasSeeded = false

    private init() {}

    /// Seed demo data if needed for demo accounts
    @MainActor
    func seedIfNeeded(context: ModelContext) async {
        guard !hasSeeded else { return }
        guard DemoAccount.isCurrentUserDemo() else { return }

        hasSeeded = true
        // Demo seeding would go here if needed
        // For now, demo accounts use real Supabase data
    }

    /// Reset seeding state
    func reset() {
        hasSeeded = false
    }
}
