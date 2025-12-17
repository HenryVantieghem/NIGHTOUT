import SwiftUI
import CoreLocation

/// View to start a new night out
@MainActor
struct StartNightView: View {
    let onNightStarted: () -> Void

    @State private var visibility: NightVisibility = .friends
    @State private var liveVisibility: LiveVisibility = .friends
    @State private var isStarting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentLocation: CLLocation?

    var body: some View {
        ScrollView {
            VStack(spacing: NightOutSpacing.xxl) {
                // Header
                VStack(spacing: NightOutSpacing.md) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(NightOutColors.primaryGradient)

                    Text("Start Your Night")
                        .font(NightOutTypography.title)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("Begin tracking your adventure")
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                }
                .padding(.top, NightOutSpacing.xxxl)

                // Settings
                VStack(spacing: NightOutSpacing.lg) {
                    // Post visibility
                    GlassCard {
                        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                            Text("Post Visibility")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Who can see your night when you post it")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            Picker("Visibility", selection: $visibility) {
                                ForEach(NightVisibility.allCases, id: \.self) { option in
                                    HStack {
                                        Image(systemName: option.icon)
                                        Text(option.displayName)
                                    }
                                    .tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    // Live visibility
                    GlassCard {
                        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                            Text("Live Location")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)

                            Text("Who can see your live location while out")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            Picker("Live Visibility", selection: $liveVisibility) {
                                ForEach(LiveVisibility.allCases, id: \.self) { option in
                                    Text(option.displayName)
                                        .tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)

                Spacer(minLength: NightOutSpacing.xxl)

                // Start button
                GlassButton(
                    "Start Night",
                    icon: "play.fill",
                    style: .primary,
                    size: .extraLarge,
                    isLoading: isStarting
                ) {
                    Task { await startNight() }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.bottom, NightOutSpacing.xxl)
            }
        }
        .nightOutBackground()
        .navigationTitle("Track")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(NightOutColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func startNight() async {
        isStarting = true
        defer { isStarting = false }

        do {
            _ = try await NightService.shared.startNight(
                startLatitude: currentLocation?.coordinate.latitude,
                startLongitude: currentLocation?.coordinate.longitude,
                visibility: visibility,
                liveVisibility: liveVisibility
            )

            NightOutHaptics.success()
            onNightStarted()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

#Preview {
    NavigationStack {
        StartNightView(onNightStarted: {})
    }
}
