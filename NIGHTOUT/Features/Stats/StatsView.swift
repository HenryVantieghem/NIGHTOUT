import SwiftUI

/// Personal statistics dashboard
@MainActor
struct StatsView: View {
    @State private var profile: SupabaseProfile?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.lg) {
                            // Main stats
                            GlassCard {
                                VStack(spacing: NightOutSpacing.lg) {
                                    Text("All Time Stats")
                                        .font(NightOutTypography.headline)
                                        .foregroundStyle(NightOutColors.chrome)

                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: NightOutSpacing.lg) {
                                        StatCard(value: "\(profile.totalNights)", label: "Nights", icon: "moon.stars")
                                        StatCard(value: formattedDuration, label: "Total Time", icon: "clock")
                                        StatCard(value: formattedDistance, label: "Distance", icon: "figure.walk")
                                        StatCard(value: "\(profile.totalDrinks)", label: "Drinks", icon: "cup.and.saucer")
                                        StatCard(value: "\(profile.totalPhotos)", label: "Photos", icon: "camera")
                                        StatCard(value: "\(profile.currentStreak)", label: "Current Streak", icon: "flame")
                                    }
                                }
                            }

                            // Streaks
                            GlassCard {
                                VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                                    Text("Streaks")
                                        .font(NightOutTypography.headline)
                                        .foregroundStyle(NightOutColors.chrome)

                                    HStack(spacing: NightOutSpacing.xxl) {
                                        VStack(spacing: NightOutSpacing.xs) {
                                            HStack(spacing: NightOutSpacing.xs) {
                                                Image(systemName: "flame.fill")
                                                    .foregroundStyle(NightOutColors.goldenHour)
                                                Text("\(profile.currentStreak)")
                                                    .font(NightOutTypography.title)
                                            }
                                            .foregroundStyle(NightOutColors.chrome)

                                            Text("Current")
                                                .font(NightOutTypography.caption)
                                                .foregroundStyle(NightOutColors.silver)
                                        }

                                        VStack(spacing: NightOutSpacing.xs) {
                                            HStack(spacing: NightOutSpacing.xs) {
                                                Image(systemName: "crown.fill")
                                                    .foregroundStyle(NightOutColors.goldenHour)
                                                Text("\(profile.longestStreak)")
                                                    .font(NightOutTypography.title)
                                            }
                                            .foregroundStyle(NightOutColors.chrome)

                                            Text("Best")
                                                .font(NightOutTypography.caption)
                                                .foregroundStyle(NightOutColors.silver)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }

                            // Achievements placeholder
                            GlassCard {
                                VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                                    HStack {
                                        Text("Achievements")
                                            .font(NightOutTypography.headline)
                                            .foregroundStyle(NightOutColors.chrome)

                                        Spacer()

                                        NavigationLink {
                                            Text("Achievements") // TODO: AchievementsView
                                        } label: {
                                            Text("See All")
                                                .font(NightOutTypography.caption)
                                                .foregroundStyle(NightOutColors.neonPink)
                                        }
                                        .buttonStyle(.plain)
                                        .contentShape(Rectangle())
                                    }

                                    HStack(spacing: NightOutSpacing.md) {
                                        AchievementBadge(icon: "star.fill", unlocked: profile.totalNights >= 1)
                                        AchievementBadge(icon: "flame.fill", unlocked: profile.currentStreak >= 7)
                                        AchievementBadge(icon: "camera.fill", unlocked: profile.totalPhotos >= 10)
                                        AchievementBadge(icon: "figure.walk", unlocked: profile.totalDistance >= 10000)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.lg)
                    }
                    .refreshable {
                        await loadProfile()
                    }
                } else {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No Stats Yet",
                        message: "Start tracking your nights to see your stats!"
                    )
                }
            }
            .nightOutBackground()
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await loadProfile()
        }
    }

    // MARK: - Computed Properties

    private var formattedDuration: String {
        guard let profile else { return "0h" }
        let hours = profile.totalDuration / 3600
        return "\(hours)h"
    }

    private var formattedDistance: String {
        guard let profile else { return "0 km" }
        return String(format: "%.0f km", profile.totalDistance / 1000)
    }

    // MARK: - Actions

    private func loadProfile() async {
        do {
            profile = try await UserService.shared.getCurrentProfile()
        } catch {
            print("Error loading profile: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Stat Card
@MainActor
struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: NightOutSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(NightOutColors.neonPink)

            Text(value)
                .font(NightOutTypography.title2)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NightOutSpacing.md)
    }
}

// MARK: - Achievement Badge
@MainActor
struct AchievementBadge: View {
    let icon: String
    let unlocked: Bool

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundStyle(unlocked ? NightOutColors.goldenHour : NightOutColors.dimmed)
            .frame(width: 50, height: 50)
            .background(unlocked ? NightOutColors.goldenHour.opacity(0.2) : NightOutColors.surface)
            .clipShape(Circle())
    }
}

#Preview {
    StatsView()
}
