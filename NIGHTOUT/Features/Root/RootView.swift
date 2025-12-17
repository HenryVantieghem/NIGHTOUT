import SwiftUI
import SwiftData

/// Root view that handles auth state routing, onboarding, and profile setup
@MainActor
struct RootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.modelContext) private var modelContext

    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var hasCompletedProfileSetup = UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup")

    var body: some View {
        Group {
            if sessionManager.isLoading {
                LoadingView("Loading...")
            } else if sessionManager.canAccessApp {
                if !hasCompletedOnboarding {
                    OnboardingView(isComplete: $hasCompletedOnboarding)
                } else if !hasCompletedProfileSetup {
                    ProfileSetupView(isComplete: $hasCompletedProfileSetup)
                } else {
                    MainTabView()
                }
            } else {
                SignInView()
            }
        }
        .task {
            // Sync data if authenticated (after session restored by NIGHTOUTApp)
            if sessionManager.isAuthenticated {
                do {
                    try await SyncService.shared.performFullSync(context: modelContext)
                } catch {
                    print("Sync error: \(error)")
                }
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            // Persist onboarding completion
            if completed {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        }
        .onChange(of: hasCompletedProfileSetup) { _, completed in
            // Persist profile setup completion
            if completed {
                UserDefaults.standard.set(true, forKey: "hasCompletedProfileSetup")
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            User.self, Night.self, Drink.self, Venue.self, Media.self,
            MoodEntry.self, Achievement.self, Friendship.self, LocationPoint.self,
            CustomDrinkTemplate.self, LiveUpdate.self, Comment.self, Song.self
        ], inMemory: true)
}
