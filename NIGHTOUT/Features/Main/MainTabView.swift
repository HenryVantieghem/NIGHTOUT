import SwiftUI
import Auth

/// Main tab bar with 5 tabs: Feed, Live, Track (center), Stats, Profile
/// Pixel-perfect redesign with custom tab bar matching screenshots
@MainActor
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var hasActiveNight = false
    @State private var showStartNight = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    LiveView()
                case 3:
                    StatsView()
                case 4:
                    ProfileView()
                default:
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            UltraTabBar(
                selectedTab: $selectedTab,
                hasActiveNight: hasActiveNight,
                onTrackTapped: {
                    NightOutHaptics.medium()
                    showStartNight = true
                }
            )
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showStartNight) {
            TrackingFlowView(
                hasActiveNight: $hasActiveNight,
                onDismiss: { showStartNight = false }
            )
        }
        .task {
            await checkActiveNight()
        }
    }

    private func checkActiveNight() async {
        guard let userId = SessionManager.shared.currentUser?.id else { return }

        do {
            if let activeNight = try await NightService.shared.getActiveNight(userId: userId) {
                hasActiveNight = activeNight.isActive
                if hasActiveNight {
                    showStartNight = true
                }
            }
        } catch {
            print("Error checking active night: \(error)")
        }
    }
}

// MARK: - Tracking Flow View
/// Full screen container for tracking flow
@MainActor
struct TrackingFlowView: View {
    @Binding var hasActiveNight: Bool
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            if hasActiveNight {
                ActiveTrackingView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                onDismiss()
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(NightOutColors.silver)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
            } else {
                StartNightView(onNightStarted: {
                    hasActiveNight = true
                })
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(NightOutColors.silver)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
