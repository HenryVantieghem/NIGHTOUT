import SwiftUI

/// Personal statistics dashboard
@MainActor
struct StatsView: View {
    @State private var profile: SupabaseProfile?
    @State private var nights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var selectedPeriod: StatsPeriod = .allTime
    @State private var showAchievements = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.lg) {
                            // Period selector
                            periodSelector

                            // Main stats
                            mainStatsCard(profile: profile)

                            // Weekly activity chart
                            weeklyActivityCard

                            // Streaks
                            streaksCard(profile: profile)

                            // Insights
                            insightsCard

                            // Achievements
                            achievementsCard(profile: profile)
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.lg)
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
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAchievements) {
                AchievementsListView()
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: NightOutSpacing.sm) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                    NightOutHaptics.light()
                } label: {
                    Text(period.displayName)
                        .font(NightOutTypography.subheadline)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(selectedPeriod == period ? NightOutColors.chrome : NightOutColors.silver)
                        .padding(.horizontal, NightOutSpacing.md)
                        .padding(.vertical, NightOutSpacing.sm)
                        .background(selectedPeriod == period ? NightOutColors.neonPink.opacity(0.2) : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedPeriod == period ? NightOutColors.neonPink : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            Spacer()
        }
    }

    // MARK: - Main Stats Card

    private func mainStatsCard(profile: SupabaseProfile) -> some View {
        GlassCard {
            VStack(spacing: NightOutSpacing.lg) {
                Text(selectedPeriod == .allTime ? "All Time Stats" : "\(selectedPeriod.displayName) Stats")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: NightOutSpacing.lg) {
                    StatsGridCard(value: "\(filteredNights.count)", label: "Nights", icon: "moon.stars")
                    StatsGridCard(value: formattedTotalDuration, label: "Total Time", icon: "clock")
                    StatsGridCard(value: formattedTotalDistance, label: "Distance", icon: "figure.walk")
                    StatsGridCard(value: "\(filteredDrinkCount)", label: "Drinks", icon: "cup.and.saucer")
                    StatsGridCard(value: "\(profile.totalPhotos)", label: "Photos", icon: "camera")
                    StatsGridCard(value: averageNightDuration, label: "Avg Duration", icon: "timer")
                }
            }
        }
    }

    // MARK: - Weekly Activity Card

    private var weeklyActivityCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                Text("Weekly Activity")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                HStack(alignment: .bottom, spacing: NightOutSpacing.sm) {
                    ForEach(weekdayData, id: \.day) { item in
                        VStack(spacing: NightOutSpacing.xs) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.count > 0 ? NightOutColors.neonPink : NightOutColors.surface)
                                .frame(width: 36, height: max(8, CGFloat(item.count) * 24))
                                .animation(.spring(response: 0.3), value: item.count)

                            Text(item.day)
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100, alignment: .bottom)
            }
        }
    }

    // MARK: - Streaks Card

    private func streaksCard(profile: SupabaseProfile) -> some View {
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

                    Spacer()

                    // Streak indicator
                    if profile.currentStreak > 0 {
                        VStack(spacing: NightOutSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    profile.currentStreak >= 7
                                        ? NightOutColors.goldenHour
                                        : NightOutColors.neonPink
                                )
                                .symbolEffect(.pulse)

                            Text(streakMessage)
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Insights Card

    private var insightsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                Text("Insights")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                VStack(spacing: NightOutSpacing.sm) {
                    StatsInsightRow(icon: "clock.fill", label: "Average night duration", value: averageNightDuration)
                    StatsInsightRow(icon: "calendar", label: "Most active day", value: mostActiveDay)
                    StatsInsightRow(icon: "figure.walk", label: "Average distance", value: averageDistance)
                    StatsInsightRow(icon: "wineglass.fill", label: "Drinks per night", value: drinksPerNight)
                }
            }
        }
    }

    // MARK: - Achievements Card

    private func achievementsCard(profile: SupabaseProfile) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                HStack {
                    Text("Achievements")
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    Spacer()

                    Button {
                        showAchievements = true
                    } label: {
                        Text("See All")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.neonPink)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }

                HStack(spacing: NightOutSpacing.md) {
                    StatsAchievementIcon(
                        icon: "star.fill",
                        title: "First Night",
                        unlocked: profile.totalNights >= 1
                    )
                    StatsAchievementIcon(
                        icon: "flame.fill",
                        title: "Week Streak",
                        unlocked: profile.longestStreak >= 7
                    )
                    StatsAchievementIcon(
                        icon: "camera.fill",
                        title: "Photographer",
                        unlocked: profile.totalPhotos >= 10
                    )
                    StatsAchievementIcon(
                        icon: "figure.walk",
                        title: "Marathon",
                        unlocked: profile.totalDistance >= 10000
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredNights: [SupabaseNight] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .allTime:
            return nights
        case .thisMonth:
            return nights.filter { calendar.isDate($0.startTime, equalTo: now, toGranularity: .month) }
        case .thisWeek:
            return nights.filter { calendar.isDate($0.startTime, equalTo: now, toGranularity: .weekOfYear) }
        }
    }

    private var formattedTotalDuration: String {
        let total = filteredNights.reduce(0) { $0 + $1.duration }
        let hours = total / 3600
        return "\(hours)h"
    }

    private var formattedTotalDistance: String {
        let total = filteredNights.reduce(0.0) { $0 + $1.distance }
        return String(format: "%.0f km", total / 1000)
    }

    private var filteredDrinkCount: Int {
        guard let profile else { return 0 }
        if selectedPeriod == .allTime {
            return profile.totalDrinks
        }
        let ratio = Double(filteredNights.count) / max(1, Double(nights.count))
        return Int(Double(profile.totalDrinks) * ratio)
    }

    private var averageNightDuration: String {
        guard !filteredNights.isEmpty else { return "0h" }
        let avg = filteredNights.reduce(0) { $0 + $1.duration } / filteredNights.count
        let hours = avg / 3600
        let minutes = (avg % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var averageDistance: String {
        guard !filteredNights.isEmpty else { return "0 m" }
        let avg = filteredNights.reduce(0.0) { $0 + $1.distance } / Double(filteredNights.count)
        if avg >= 1000 {
            return String(format: "%.1f km", avg / 1000)
        }
        return String(format: "%.0f m", avg)
    }

    private var mostActiveDay: String {
        guard !nights.isEmpty else { return "N/A" }
        let calendar = Calendar.current
        var dayCounts: [Int: Int] = [:]

        for night in nights {
            let weekday = calendar.component(.weekday, from: night.startTime)
            dayCounts[weekday, default: 0] += 1
        }

        let maxDay = dayCounts.max(by: { $0.value < $1.value })?.key ?? 1
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[maxDay - 1]
    }

    private var drinksPerNight: String {
        guard !filteredNights.isEmpty else { return "0" }
        let avg = Double(filteredDrinkCount) / Double(filteredNights.count)
        return String(format: "%.1f", avg)
    }

    private var weekdayData: [(day: String, count: Int)] {
        let calendar = Calendar.current
        let symbols = ["M", "T", "W", "T", "F", "S", "S"]

        var counts: [Int: Int] = [:]
        for night in nights {
            let weekday = calendar.component(.weekday, from: night.startTime)
            let adjustedDay = weekday == 1 ? 7 : weekday - 1
            counts[adjustedDay, default: 0] += 1
        }

        return (1...7).map { day in
            (day: symbols[day - 1], count: counts[day] ?? 0)
        }
    }

    private var streakMessage: String {
        guard let profile else { return "" }
        if profile.currentStreak >= 7 {
            return "On fire!"
        } else if profile.currentStreak >= 3 {
            return "Keep it up!"
        }
        return "Building..."
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

// MARK: - Stats Period

enum StatsPeriod: String, CaseIterable {
    case allTime = "all"
    case thisMonth = "month"
    case thisWeek = "week"

    var displayName: String {
        switch self {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .thisWeek: return "This Week"
        }
    }
}

// MARK: - Stats Grid Card

@MainActor
struct StatsGridCard: View {
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

// MARK: - Stats Achievement Icon

@MainActor
struct StatsAchievementIcon: View {
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
    }
}

// MARK: - Stats Insight Row

@MainActor
struct StatsInsightRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(NightOutColors.neonPink)
                .frame(width: 24)

            Text(label)
                .font(NightOutTypography.body)
                .foregroundStyle(NightOutColors.silver)

            Spacer()

            Text(value)
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.chrome)
        }
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
                    .foregroundStyle(NightOutColors.neonPink)
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
        case .firstFriend: return false // Would need friend count
        case .tenFriends: return false
        case .socialButterfly: return false
        case .weekStreak: return profile.longestStreak >= 7
        case .monthStreak: return profile.longestStreak >= 30
        case .marathoner: return profile.totalDistance >= 42000
        case .explorer: return false // Would need venue count
        case .nightOwl: return false // Would need time check
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
        GlassCard {
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
        }
    }
}

#Preview {
    StatsView()
}
