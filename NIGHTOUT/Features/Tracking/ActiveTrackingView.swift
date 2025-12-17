import SwiftUI
import Auth

/// Active night tracking dashboard
@MainActor
struct ActiveTrackingView: View {
    @State private var night: SupabaseNight?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showAddDrink = false
    @State private var showAddVenue = false
    @State private var showEndNight = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let night {
                ScrollView {
                    VStack(spacing: NightOutSpacing.xxl) {
                        // Timer display
                        VStack(spacing: NightOutSpacing.sm) {
                            LiveIndicator()

                            Text(formattedTime)
                                .font(NightOutTypography.timer)
                                .foregroundStyle(NightOutColors.chrome)
                                .monospacedDigit()

                            if let venueName = night.currentVenueName {
                                HStack(spacing: NightOutSpacing.xs) {
                                    Image(systemName: "mappin")
                                    Text(venueName)
                                }
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                            }
                        }
                        .padding(.top, NightOutSpacing.xl)

                        // Quick stats
                        GlassCard {
                            HStack {
                                ProfileStatItem(
                                    value: formattedDistance,
                                    label: "Distance",
                                    icon: "figure.walk"
                                )
                                ProfileStatItem(
                                    value: "0",
                                    label: "Drinks",
                                    icon: "cup.and.saucer"
                                )
                                ProfileStatItem(
                                    value: "0",
                                    label: "Venues",
                                    icon: "mappin"
                                )
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        // Action buttons
                        VStack(spacing: NightOutSpacing.md) {
                            HStack(spacing: NightOutSpacing.md) {
                                GlassButton("Add Drink", icon: "plus.circle", style: .secondary, size: .large) {
                                    showAddDrink = true
                                }

                                GlassButton("Check In", icon: "mappin.circle", style: .secondary, size: .large) {
                                    showAddVenue = true
                                }
                            }

                            GlassButton("Take Photo", icon: "camera", style: .secondary, size: .large) {
                                // TODO: Camera
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        Spacer(minLength: NightOutSpacing.xxl)

                        // End night button
                        GlassButton("End Night", icon: "moon.zzz", style: .destructive, size: .large) {
                            showEndNight = true
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.bottom, NightOutSpacing.xxl)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "No Active Night",
                    message: "Something went wrong. Please start a new night."
                )
            }
        }
        .nightOutBackground()
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(NightOutColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddDrink) {
            if let night {
                AddDrinkView(nightId: night.id)
            }
        }
        .sheet(isPresented: $showAddVenue) {
            if let night {
                AddVenueView(nightId: night.id)
            }
        }
        .sheet(isPresented: $showEndNight) {
            if let night {
                EndNightView(night: night)
            }
        }
        .task {
            await loadActiveNight()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Computed Properties

    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var formattedDistance: String {
        guard let night else { return "0m" }
        if night.distance >= 1000 {
            return String(format: "%.1f km", night.distance / 1000)
        }
        return String(format: "%.0f m", night.distance)
    }

    // MARK: - Actions

    private func loadActiveNight() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            night = try await NightService.shared.getActiveNight(userId: userId)
            if let night {
                elapsedTime = Date().timeIntervalSince(night.startTime)
            }
        } catch {
            print("Error loading active night: \(error)")
        }

        isLoading = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        ActiveTrackingView()
    }
}
