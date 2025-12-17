import SwiftUI

/// Sheet to end night and create post with full summary
@MainActor
struct EndNightView: View {
    @Environment(\.dismiss) private var dismiss
    let night: SupabaseNight
    let drinks: [SupabaseDrink]

    @State private var title = ""
    @State private var caption = ""
    @State private var isPublic = true
    @State private var isEnding = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfetti = false
    @State private var hasEnded = false

    init(night: SupabaseNight, drinks: [SupabaseDrink] = []) {
        self.night = night
        self.drinks = drinks
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: NightOutSpacing.xxl) {
                        // Night Summary Header
                        SummaryHeader(duration: formattedDuration)

                        // Stats Cards
                        StatsGrid(
                            duration: formattedDuration,
                            distance: formattedDistance,
                            drinkCount: drinks.count,
                            standardDrinks: totalStandardDrinks
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        // Drinks summary
                        if !drinks.isEmpty {
                            DrinksSummary(drinks: drinks)
                        }

                        // Post form
                        PostForm(
                            title: $title,
                            caption: $caption,
                            isPublic: $isPublic
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        Spacer(minLength: NightOutSpacing.xxl)

                        // Action buttons
                        VStack(spacing: NightOutSpacing.md) {
                            GlassButton(
                                isPublic ? "End & Share Night" : "End Night",
                                icon: "checkmark.circle.fill",
                                style: .prominent,
                                size: .large,
                                isLoading: isEnding
                            ) {
                                Task { await endNight() }
                            }

                            Button("Discard Night") {
                                // TODO: Confirm and delete
                                NightOutHaptics.warning()
                            }
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.liveRed)
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.bottom, NightOutSpacing.xxl)
                    }
                    .padding(.top, NightOutSpacing.lg)
                }
                .nightOutBackground()
                .navigationTitle("End Night")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(NightOutColors.silver)
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }

                // Confetti overlay
                ConfettiView(isShowing: $showConfetti)
            }
        }
    }

    // MARK: - Computed Properties

    private var formattedDuration: String {
        let elapsed = Date().timeIntervalSince(night.startTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var formattedDistance: String {
        if night.distance >= 1000 {
            return String(format: "%.1f km", night.distance / 1000)
        }
        return String(format: "%.0f m", night.distance)
    }

    private var totalStandardDrinks: Double {
        drinks.reduce(0) { total, drink in
            let drinkType = DrinkType(rawValue: drink.type) ?? .custom
            return total + drinkType.standardDrinks
        }
    }

    // MARK: - Actions

    private func endNight() async {
        isEnding = true
        defer { isEnding = false }

        let duration = Int(Date().timeIntervalSince(night.startTime))

        do {
            try await NightService.shared.endNight(
                id: night.id,
                title: title.isEmpty ? nil : title,
                caption: caption.isEmpty ? nil : caption,
                duration: duration,
                distance: night.distance,
                routePolyline: night.routePolyline
            )

            // Update user stats
            try await UserService.shared.incrementStats(
                nights: 1,
                duration: duration,
                distance: night.distance
            )

            // Show confetti if posting
            if isPublic {
                showConfetti = true
                NightOutHaptics.success()

                // Wait for confetti then dismiss
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            } else {
                NightOutHaptics.success()
            }

            hasEnded = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

// MARK: - Summary Header
@MainActor
struct SummaryHeader: View {
    let duration: String

    var body: some View {
        VStack(spacing: NightOutSpacing.md) {
            // Moon icon with glow
            ZStack {
                Circle()
                    .fill(NightOutColors.partyPurple.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(NightOutColors.primaryGradient)
            }

            Text("What a Night! 🎉")
                .font(NightOutTypography.title)
                .foregroundStyle(NightOutColors.chrome)

            Text("You were out for \(duration)")
                .font(NightOutTypography.body)
                .foregroundStyle(NightOutColors.silver)
        }
    }
}

// MARK: - Stats Grid
@MainActor
struct StatsGrid: View {
    let duration: String
    let distance: String
    let drinkCount: Int
    let standardDrinks: Double

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: NightOutSpacing.md) {
            SummaryStatCard(
                icon: "clock.fill",
                value: duration,
                label: "Duration",
                color: NightOutColors.electricBlue
            )

            SummaryStatCard(
                icon: "figure.walk",
                value: distance,
                label: "Distance",
                color: NightOutColors.successGreen
            )

            SummaryStatCard(
                icon: "wineglass.fill",
                value: "\(drinkCount)",
                label: "Drinks",
                color: NightOutColors.neonPink
            )

            SummaryStatCard(
                icon: "drop.fill",
                value: String(format: "%.1f", standardDrinks),
                label: "Std Drinks",
                color: NightOutColors.goldenHour
            )
        }
    }
}

@MainActor
struct SummaryStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: NightOutSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            Text(value)
                .font(NightOutTypography.statNumber)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.dimmed)
        }
        .frame(maxWidth: .infinity)
        .padding(NightOutSpacing.lg)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.lg))
    }
}

// MARK: - Drinks Summary
@MainActor
struct DrinksSummary: View {
    let drinks: [SupabaseDrink]

    var body: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            HStack {
                Text("Tonight's Drinks")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Spacer()

                Text("\(drinks.count) total")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)

            // Horizontal scroll of drink emojis
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NightOutSpacing.sm) {
                    ForEach(drinks, id: \.id) { drink in
                        let drinkType = DrinkType(rawValue: drink.type) ?? .custom
                        Text(drink.customEmoji ?? drinkType.emoji)
                            .font(.system(size: 32))
                            .padding(NightOutSpacing.sm)
                            .background(drinkType.color.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }

            // Drink type breakdown
            GlassCard {
                VStack(spacing: NightOutSpacing.sm) {
                    ForEach(drinkTypeCounts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                        HStack {
                            Text(type.emoji)
                                .font(.system(size: 20))

                            Text(type.displayName)
                                .font(NightOutTypography.body)
                                .foregroundStyle(NightOutColors.chrome)

                            Spacer()

                            Text("×\(count)")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(type.color)
                        }
                    }
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }

    private var drinkTypeCounts: [DrinkType: Int] {
        var counts: [DrinkType: Int] = [:]
        for drink in drinks {
            let type = DrinkType(rawValue: drink.type) ?? .custom
            counts[type, default: 0] += 1
        }
        return counts
    }
}

// MARK: - Post Form
@MainActor
struct PostForm: View {
    @Binding var title: String
    @Binding var caption: String
    @Binding var isPublic: Bool

    var body: some View {
        VStack(spacing: NightOutSpacing.lg) {
            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                Text("Title (optional)")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)

                TextField("Friday Night Out", text: $title)
                    .textFieldStyle(GlassTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                Text("Caption (optional)")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)

                TextField("What a night!", text: $caption, axis: .vertical)
                    .textFieldStyle(GlassTextFieldStyle())
                    .lineLimit(3...6)
            }

            // Share toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: NightOutSpacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(NightOutColors.neonPink)
                        Text("Share to Feed")
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)
                    }

                    Text("Share your night with friends")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }

                Spacer()

                Toggle("", isOn: $isPublic)
                    .labelsHidden()
                    .tint(NightOutColors.neonPink)
            }
            .padding(NightOutSpacing.md)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
    }
}

#Preview {
    EndNightView(
        night: SupabaseNight(
            id: UUID(),
            userId: UUID(),
            title: nil,
            caption: nil,
            startTime: Date().addingTimeInterval(-7200),
            endTime: nil,
            duration: 0,
            isActive: true,
            isPublic: true,
            visibility: "friends",
            liveVisibility: "friends",
            startLatitude: nil,
            startLongitude: nil,
            currentLatitude: nil,
            currentLongitude: nil,
            currentVenueName: "The Local Pub",
            distance: 2500,
            routePolyline: nil,
            likeCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        ),
        drinks: []
    )
}
