import SwiftUI
import Auth

/// Main tab bar with 5 tabs: Home, Live, Track (center), Stats, Profile
@MainActor
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var hasActiveNight = false
    @State private var showStartNight = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                LiveView()
                    .tag(1)

                // Placeholder for center tab - actual content shown in sheet/fullscreen
                Color.clear
                    .tag(2)

                StatsView()
                    .tag(3)

                ProfileView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Custom Tab Bar
            CustomTabBar(
                selectedTab: $selectedTab,
                hasActiveNight: hasActiveNight,
                onTrackTapped: {
                    NightOutHaptics.medium()
                    showStartNight = true
                }
            )
        }
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

// MARK: - Custom Tab Bar
@MainActor
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let hasActiveNight: Bool
    let onTrackTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Home
            TabBarButton(
                icon: "house.fill",
                label: "Home",
                isSelected: selectedTab == 0
            ) {
                NightOutHaptics.light()
                selectedTab = 0
            }

            // Live
            TabBarButton(
                icon: "map.fill",
                label: "Live",
                isSelected: selectedTab == 1
            ) {
                NightOutHaptics.light()
                selectedTab = 1
            }

            // Center Track Button (prominent)
            CenterTrackButton(
                hasActiveNight: hasActiveNight,
                action: onTrackTapped
            )

            // Stats
            TabBarButton(
                icon: "chart.bar.fill",
                label: "Stats",
                isSelected: selectedTab == 3
            ) {
                NightOutHaptics.light()
                selectedTab = 3
            }

            // Profile
            TabBarButton(
                icon: "person.fill",
                label: "Profile",
                isSelected: selectedTab == 4
            ) {
                NightOutHaptics.light()
                selectedTab = 4
            }
        }
        .padding(.horizontal, NightOutSpacing.md)
        .padding(.top, NightOutSpacing.md)
        .padding(.bottom, 34) // Safe area
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(NightOutColors.background.opacity(0.5))
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [NightOutColors.glassBorder, Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea()
        )
    }
}

// MARK: - Tab Bar Button
@MainActor
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? NightOutColors.neonPink : NightOutColors.silver)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? NightOutColors.neonPink : NightOutColors.dimmed)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Center Track Button
@MainActor
struct CenterTrackButton: View {
    let hasActiveNight: Bool
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect when active
                if hasActiveNight {
                    Circle()
                        .fill(NightOutColors.liveRed.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.5 : 0.8)
                }

                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: hasActiveNight
                                ? [NightOutColors.liveRed, NightOutColors.liveRed]
                                : [NightOutColors.neonPink, NightOutColors.partyPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: (hasActiveNight ? NightOutColors.liveRed : NightOutColors.neonPink).opacity(0.5), radius: 10)

                // Icon
                Image(systemName: hasActiveNight ? "record.circle" : "plus")
                    .font(.system(size: hasActiveNight ? 24 : 26, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(y: -10) // Raise above tab bar
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .frame(maxWidth: .infinity)
        .onAppear {
            if hasActiveNight {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: hasActiveNight) { _, active in
            if active {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
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
