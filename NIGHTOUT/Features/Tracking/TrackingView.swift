import SwiftUI
import Auth

/// Container view for tracking states
@MainActor
struct TrackingView: View {
    @State private var hasActiveNight = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if hasActiveNight {
                ActiveTrackingView()
            } else {
                StartNightView(onNightStarted: {
                    hasActiveNight = true
                })
            }
        }
        .task {
            await checkActiveNight()
        }
    }

    private func checkActiveNight() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            if let activeNight = try await NightService.shared.getActiveNight(userId: userId) {
                hasActiveNight = activeNight.isActive
            }
        } catch {
            print("Error checking active night: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    TrackingView()
}
