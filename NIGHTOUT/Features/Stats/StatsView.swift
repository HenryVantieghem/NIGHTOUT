import SwiftUI

/// Personal statistics dashboard - Pixel-perfect redesign
@MainActor
struct StatsView: View {
    @State private var profile: SupabaseProfile?
    @State private var nights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var showAchievements = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.xxl) {
                            // All Time section
                            allTimeSection(profile: profile)

                            // This Month section
                            thisMonthSection

                            // Achievements section
                            achievementsSection(profile: profile)

                            Spacer(minLength: NightOutSpacing.tabBarTotal)
                        }
                        .padding(.top, NightOutSpacing.lg)
                    }
                    .refreshable {
                        await loadData()
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
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAchievements) {
                AchievementsListView()
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - All Time Section

    private func allTimeSection(profile: SupabaseProfile) -> some View {
        VStack(spacing: NightOutSpacing.md) {
            UltraSectionHeader(title: "ALL TIME")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                StatCard(emoji: Emoji.nights, value: "\(profile.totalNights)", label: "Nights")
                StatCard(emoji: Emoji.time, value: formattedTotalTime(profile), label: "Total")
                StatCard(emoji: Emoji.distance, value: formattedDistance(profile), label: "Distance")
                StatCard(emoji: Emoji.drinks, value: "\(profile.totalDrinks)", label: "Drinks")
                StatCard(emoji: Emoji.songs, value: "\(profile.totalSongs)", label: "Songs")
                StatCard(emoji: Emoji.photos, value: "\(profile.totalPhotos)", label: "Photos")
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }

    // MARK: - This Month Section

    private var thisMonthSection: some View {
        VStack(spacing: NightOutSpacing.md) {
            UltraSectionHeader(
                title: "THIS MONTH",
                rightText: currentMonthYear
            )

            ActivityChartCard()
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }

    // MARK: - Achievements Section

    private func achievementsSection(profile: SupabaseProfile) -> some View {
        VStack(spacing: NightOutSpacing.md) {
            UltraSectionHeader(
                title: "ACHIEVEMENTS",
                rightText: "See All",
                rightAction: { showAchievements = true }
            )

            // Preview of 4 achievements
            HStack(spacing: NightOutSpacing.md) {
                AchievementPreviewIcon(
                    icon: "star.fill",
                    title: "First Night",
                    unlocked: profile.totalNights >= 1
                )
                AchievementPreviewIcon(
                    icon: "flame.fill",
                    title: "Week Streak",
                    unlocked: profile.longestStreak >= 7
                )
                AchievementPreviewIcon(
                    icon: "camera.fill",
                    title: "Photographer",
                    unlocked: profile.totalPhotos >= 10
                )
                AchievementPreviewIcon(
                    icon: "figure.walk",
                    title: "Marathon",
                    unlocked: profile.totalDistance >= 10000
                )
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }

    // MARK: - Computed Properties

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private func formattedTotalTime(_ profile: SupabaseProfile) -> String {
        let totalSeconds = nights.reduce(0) { $0 + $1.duration }
        let hours = totalSeconds / 3600
        if hours >= 1 {
            return "\(hours)h"
        }
        let minutes = totalSeconds / 60
        return "\(minutes)m"
    }

    private func formattedDistance(_ profile: SupabaseProfile) -> String {
        let totalMeters = profile.totalDistance
        if totalMeters >= 1609 { // 1 mile in meters
            let miles = totalMeters / 1609.34
            return String(format: "%.1f mi", miles)
        }
        return String(format: "%.0f m", totalMeters)
    }

    // MARK: - Actions

    private func loadData() async {
        do {
            profile = try await UserService.shared.getCurrentProfile()
            nights = try await NightService.shared.getMyNights(limit: 100)
        } catch {
            print("Error loading stats: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Achievement Preview Icon

@MainActor
struct AchievementPreviewIcon: View {
    let icon: String
    let title: String
    let unlocked: Bool

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(unlocked ? NightOutColors.goldenHour : NightOutColors.dimmed)
                .frame(width: 50, height: 50)
                .background(unlocked ? NightOutColors.goldenHour.opacity(0.2) : NightOutColors.surface)
                .clipShape(Circle())

            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(unlocked ? NightOutColors.chrome : NightOutColors.dimmed)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievements List View

@MainActor
struct AchievementsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: SupabaseProfile?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    LazyVStack(spacing: NightOutSpacing.md) {
                        ForEach(AchievementType.allCases) { achievement in
                            AchievementListRow(
                                achievementType: achievement,
                                profile: profile
                            )
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.vertical, NightOutSpacing.lg)
                } else {
                    LoadingView()
                }
            }
            .nightOutBackground()
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.partyPurple)
                }
            }
        }
        .task {
            profile = try? await UserService.shared.getCurrentProfile()
        }
    }
}

// MARK: - Achievement List Row

@MainActor
struct AchievementListRow: View {
    let achievementType: AchievementType
    let profile: SupabaseProfile

    private var isUnlocked: Bool {
        switch achievementType {
        case .firstNight: return profile.totalNights >= 1
        case .tenNights: return profile.totalNights >= 10
        case .fiftyNights: return profile.totalNights >= 50
        case .hundredNights: return profile.totalNights >= 100
        case .firstFriend: return false
        case .tenFriends: return false
        case .socialButterfly: return false
        case .weekStreak: return profile.longestStreak >= 7
        case .monthStreak: return profile.longestStreak >= 30
        case .marathoner: return profile.totalDistance >= 42000
        case .explorer: return false
        case .nightOwl: return false
        case .earlyBird: return false
        case .photoGenic: return profile.totalPhotos >= 100
        }
    }

    private var progress: Double {
        switch achievementType {
        case .firstNight: return min(1, Double(profile.totalNights) / 1)
        case .tenNights: return min(1, Double(profile.totalNights) / 10)
        case .fiftyNights: return min(1, Double(profile.totalNights) / 50)
        case .hundredNights: return min(1, Double(profile.totalNights) / 100)
        case .firstFriend: return 0
        case .tenFriends: return 0
        case .socialButterfly: return 0
        case .weekStreak: return min(1, Double(profile.longestStreak) / 7)
        case .monthStreak: return min(1, Double(profile.longestStreak) / 30)
        case .marathoner: return min(1, profile.totalDistance / 42000)
        case .explorer: return 0
        case .nightOwl: return 0
        case .earlyBird: return 0
        case .photoGenic: return min(1, Double(profile.totalPhotos) / 100)
        }
    }

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            Image(systemName: achievementType.icon)
                .font(.system(size: 28))
                .foregroundStyle(isUnlocked ? NightOutColors.goldenHour : NightOutColors.dimmed)
                .frame(width: 56, height: 56)
                .background(isUnlocked ? NightOutColors.goldenHour.opacity(0.2) : NightOutColors.surface)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                Text(achievementType.displayName)
                    .font(NightOutTypography.headline)
                    .foregroundStyle(isUnlocked ? NightOutColors.chrome : NightOutColors.silver)

                Text(achievementType.description)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)

                if !isUnlocked {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(NightOutColors.surface)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(NightOutColors.neonPink)
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(NightOutColors.successGreen)
            }
        }
        .padding(NightOutSpacing.md)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Achievement Type

enum AchievementType: String, CaseIterable, Identifiable {
    case firstNight
    case tenNights
    case fiftyNights
    case hundredNights
    case firstFriend
    case tenFriends
    case socialButterfly
    case weekStreak
    case monthStreak
    case marathoner
    case explorer
    case nightOwl
    case earlyBird
    case photoGenic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .firstNight: return "First Night Out"
        case .tenNights: return "Night Owl"
        case .fiftyNights: return "Party Animal"
        case .hundredNights: return "Legend"
        case .firstFriend: return "First Friend"
        case .tenFriends: return "Social Starter"
        case .socialButterfly: return "Social Butterfly"
        case .weekStreak: return "Week Warrior"
        case .monthStreak: return "Month Master"
        case .marathoner: return "Marathoner"
        case .explorer: return "Explorer"
        case .nightOwl: return "Night Owl"
        case .earlyBird: return "Early Bird"
        case .photoGenic: return "Photogenic"
        }
    }

    var description: String {
        switch self {
        case .firstNight: return "Complete your first night out"
        case .tenNights: return "Complete 10 nights out"
        case .fiftyNights: return "Complete 50 nights out"
        case .hundredNights: return "Complete 100 nights out"
        case .firstFriend: return "Add your first friend"
        case .tenFriends: return "Add 10 friends"
        case .socialButterfly: return "Add 50 friends"
        case .weekStreak: return "Track 7 nights in a row"
        case .monthStreak: return "Track 30 nights in a row"
        case .marathoner: return "Walk 42km total"
        case .explorer: return "Visit 50 different venues"
        case .nightOwl: return "Stay out past 3am"
        case .earlyBird: return "Start a night before 6pm"
        case .photoGenic: return "Take 100 photos"
        }
    }

    var icon: String {
        switch self {
        case .firstNight: return "star.fill"
        case .tenNights: return "moon.stars.fill"
        case .fiftyNights: return "party.popper.fill"
        case .hundredNights: return "crown.fill"
        case .firstFriend: return "person.fill"
        case .tenFriends: return "person.2.fill"
        case .socialButterfly: return "person.3.fill"
        case .weekStreak: return "flame.fill"
        case .monthStreak: return "flame.circle.fill"
        case .marathoner: return "figure.walk"
        case .explorer: return "map.fill"
        case .nightOwl: return "owl.fill"
        case .earlyBird: return "sunrise.fill"
        case .photoGenic: return "camera.fill"
        }
    }
}

#Preview {
    StatsView()
}
