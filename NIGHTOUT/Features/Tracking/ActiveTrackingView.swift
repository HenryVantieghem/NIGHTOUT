import SwiftUI
import PhotosUI
import UIKit
import Auth

/// Active night tracking dashboard - Strava-style with real-time stats
@MainActor
struct ActiveTrackingView: View {
    @State private var night: SupabaseNight?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var drinks: [SupabaseDrink] = []
    @State private var currentMood: MoodLevel = .good

    // Sheet states
    @State private var showAddDrink = false
    @State private var showAddVenue = false
    @State private var showEndNight = false
    @State private var showMoodPicker = false
    @State private var showCamera = false

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?

    // UI state
    @State private var isLoading = true
    @State private var isPulsing = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let night {
                ScrollView {
                    VStack(spacing: NightOutSpacing.xl) {
                        // Timer header with pulsing indicator
                        TimerHeader(
                            elapsedTime: elapsedTime,
                            venueName: night.currentVenueName,
                            isPulsing: $isPulsing
                        )
                        .padding(.top, NightOutSpacing.lg)

                        // Quick stats row
                        QuickStatsRow(
                            distance: night.distance,
                            drinkCount: drinks.count,
                            venueCount: 0 // TODO: Track venues
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        // Drinks section
                        if !drinks.isEmpty {
                            DrinksDisplaySection(drinks: drinks)
                        }

                        // Quick action buttons
                        QuickActionsGrid(
                            onAddDrink: { showAddDrink = true },
                            onCheckIn: { showAddVenue = true },
                            onTakePhoto: { showCamera = true },
                            onMood: { showMoodPicker = true }
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        // Current mood indicator
                        MoodIndicator(mood: currentMood) {
                            showMoodPicker = true
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        Spacer(minLength: NightOutSpacing.xxxl)

                        // End night button
                        GlassButton(
                            "End Night",
                            icon: "moon.zzz.fill",
                            style: .destructive,
                            size: .large
                        ) {
                            NightOutHaptics.medium()
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
        .sheet(isPresented: $showAddDrink) {
            if let night {
                AddDrinkView(nightId: night.id) {
                    Task { await loadDrinks() }
                }
            }
        }
        .sheet(isPresented: $showAddVenue) {
            if let night {
                AddVenueView(nightId: night.id)
            }
        }
        .sheet(isPresented: $showEndNight) {
            if let night {
                EndNightView(night: night, drinks: drinks)
            }
        }
        .sheet(isPresented: $showMoodPicker) {
            if let night {
                MoodPickerSheet(nightId: night.id, currentMood: $currentMood)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraSheet(selectedPhoto: $selectedPhoto)
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                await handlePhotoSelection(newItem)
            }
        }
        .task {
            await loadActiveNight()
            await loadDrinks()
            startTimer()
            startPulseAnimation()
        }
        .onDisappear {
            stopTimer()
        }
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

    private func loadDrinks() async {
        guard let night else { return }

        do {
            drinks = try await DrinkService.shared.getDrinks(nightId: night.id)
        } catch {
            print("Error loading drinks: \(error)")
        }
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

    private func startPulseAnimation() {
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let night else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                // Upload photo
                _ = try await MediaService.shared.uploadPhoto(
                    nightId: night.id,
                    image: uiImage
                )
                NightOutHaptics.success()
            }
        } catch {
            print("Error uploading photo: \(error)")
            NightOutHaptics.error()
        }
    }
}

// MARK: - Timer Header
@MainActor
struct TimerHeader: View {
    let elapsedTime: TimeInterval
    let venueName: String?
    @Binding var isPulsing: Bool

    var body: some View {
        VStack(spacing: NightOutSpacing.md) {
            // Live indicator with pulse
            HStack(spacing: NightOutSpacing.sm) {
                Circle()
                    .fill(NightOutColors.liveRed)
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .shadow(color: NightOutColors.liveRed.opacity(0.5), radius: isPulsing ? 8 : 4)

                Text("LIVE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(NightOutColors.liveRed)
                    .tracking(2)
            }
            .padding(.horizontal, NightOutSpacing.md)
            .padding(.vertical, NightOutSpacing.xs)
            .background(NightOutColors.liveRed.opacity(0.1))
            .clipShape(Capsule())

            // Timer
            Text(formattedTime)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(NightOutColors.chrome)
                .monospacedDigit()
                .contentTransition(.numericText())

            // Venue name
            if let venueName {
                HStack(spacing: NightOutSpacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(NightOutColors.neonPink)
                    Text(venueName)
                        .font(NightOutTypography.subheadline)
                        .foregroundStyle(NightOutColors.silver)
                }
            }
        }
    }

    private var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Quick Stats Row
@MainActor
struct QuickStatsRow: View {
    let distance: Double
    let drinkCount: Int
    let venueCount: Int

    var body: some View {
        GlassCard {
            HStack(spacing: 0) {
                StatItem(
                    value: formattedDistance,
                    label: "Distance",
                    icon: "figure.walk",
                    color: NightOutColors.electricBlue
                )

                Divider()
                    .frame(height: 40)
                    .background(NightOutColors.glassBorder)

                StatItem(
                    value: "\(drinkCount)",
                    label: "Drinks",
                    icon: "wineglass.fill",
                    color: NightOutColors.neonPink
                )

                Divider()
                    .frame(height: 40)
                    .background(NightOutColors.glassBorder)

                StatItem(
                    value: "\(venueCount)",
                    label: "Venues",
                    icon: "mappin.circle.fill",
                    color: NightOutColors.goldenHour
                )
            }
        }
    }

    private var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        }
        return String(format: "%.0fm", distance)
    }
}

@MainActor
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)

            Text(value)
                .font(NightOutTypography.statNumber)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.dimmed)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Drinks Display Section
@MainActor
struct DrinksDisplaySection: View {
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

            // Emoji display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NightOutSpacing.sm) {
                    ForEach(drinks, id: \.id) { drink in
                        DrinkBubble(drink: drink)
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
    }
}

@MainActor
struct DrinkBubble: View {
    let drink: SupabaseDrink

    var body: some View {
        let drinkType = DrinkType(rawValue: drink.type) ?? .custom

        VStack(spacing: 4) {
            Text(drink.customEmoji ?? drinkType.emoji)
                .font(.system(size: 32))

            Text(timeAgo)
                .font(.system(size: 10))
                .foregroundStyle(NightOutColors.dimmed)
        }
        .padding(NightOutSpacing.sm)
        .background(drinkType.color.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(drink.timestamp)
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        return "\(minutes / 60)h ago"
    }
}

// MARK: - Quick Actions Grid
@MainActor
struct QuickActionsGrid: View {
    let onAddDrink: () -> Void
    let onCheckIn: () -> Void
    let onTakePhoto: () -> Void
    let onMood: () -> Void

    var body: some View {
        VStack(spacing: NightOutSpacing.md) {
            HStack(spacing: NightOutSpacing.md) {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    label: "Add Drink",
                    color: NightOutColors.neonPink,
                    action: onAddDrink
                )

                QuickActionButton(
                    icon: "mappin.circle.fill",
                    label: "Check In",
                    color: NightOutColors.goldenHour,
                    action: onCheckIn
                )
            }

            HStack(spacing: NightOutSpacing.md) {
                QuickActionButton(
                    icon: "camera.fill",
                    label: "Photo",
                    color: NightOutColors.electricBlue,
                    action: onTakePhoto
                )

                QuickActionButton(
                    icon: "face.smiling.fill",
                    label: "Mood",
                    color: NightOutColors.partyPurple,
                    action: onMood
                )
            }
        }
    }
}

@MainActor
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.light()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)

                Text(label)
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Spacer()
            }
            .padding(NightOutSpacing.md)
            .frame(maxWidth: .infinity)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Mood Indicator
@MainActor
struct MoodIndicator: View {
    let mood: MoodLevel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Current Mood")
                    .font(NightOutTypography.subheadline)
                    .foregroundStyle(NightOutColors.silver)

                Spacer()

                HStack(spacing: NightOutSpacing.sm) {
                    Text(mood.emoji)
                        .font(.system(size: 24))

                    Text(mood.displayName)
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(NightOutColors.dimmed)
                }
            }
            .padding(NightOutSpacing.md)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Mood Picker Sheet
@MainActor
struct MoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let nightId: UUID
    @Binding var currentMood: MoodLevel

    var body: some View {
        NavigationStack {
            VStack(spacing: NightOutSpacing.xxl) {
                Text("How are you feeling?")
                    .font(NightOutTypography.title2)
                    .foregroundStyle(NightOutColors.chrome)
                    .padding(.top, NightOutSpacing.xl)

                HStack(spacing: NightOutSpacing.lg) {
                    ForEach(MoodLevel.allCases) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: currentMood == mood
                        ) {
                            currentMood = mood
                            NightOutHaptics.medium()
                            // TODO: Save mood to Supabase
                            dismiss()
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .nightOutBackground()
            .navigationTitle("Log Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

@MainActor
struct MoodButton: View {
    let mood: MoodLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NightOutSpacing.sm) {
                Text(mood.emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.2 : 1.0)

                Text(mood.displayName)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
            }
            .padding(NightOutSpacing.md)
            .background(isSelected ? NightOutColors.partyPurple.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .animation(NightOutAnimation.bouncy, value: isSelected)
    }
}

// MARK: - Camera Sheet
@MainActor
struct CameraSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPhoto: PhotosPickerItem?

    // Capture static values for Sendable closure
    private let captionFont = NightOutTypography.caption
    private let silverColor = NightOutColors.silver
    private let smallSpacing = NightOutSpacing.sm

    var body: some View {
        NavigationStack {
            VStack(spacing: NightOutSpacing.xxl) {
                Spacer()

                VStack(spacing: NightOutSpacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(NightOutColors.neonPink)

                    Text("Capture the Moment")
                        .font(NightOutTypography.title2)
                        .foregroundStyle(NightOutColors.chrome)
                }

                Spacer()

                VStack(spacing: NightOutSpacing.md) {
                    // Camera button would launch actual camera
                    GlassButton("Take Photo", icon: "camera.fill", style: .primary, size: .large) {
                        // TODO: Launch actual camera
                        NightOutHaptics.medium()
                    }

                    // Photo picker
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: smallSpacing) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Gallery")
                        }
                        .font(captionFont)
                        .foregroundStyle(silverColor)
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.bottom, NightOutSpacing.xxl)
            }
            .nightOutBackground()
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
        }
        .onChange(of: selectedPhoto) { _, _ in
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        ActiveTrackingView()
    }
}
