import SwiftUI
import PhotosUI
import MapKit
import UIKit
import Auth

/// Active night tracking dashboard - Pixel-perfect Strava-style redesign
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
    @State private var showSongPicker = false

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem?

    // UI state
    @State private var isLoading = true
    @State private var isPulsing = false

    // Map region
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let night {
                ZStack {
                    // Map background
                    mapBackground

                    // Content overlay
                    VStack(spacing: 0) {
                        // Header with recording indicator
                        headerBar

                        // Timer card
                        TimerCard(
                            time: formattedTime,
                            vibeName: night.title,
                            friendCount: 0,
                            isPulsing: $isPulsing
                        )
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.top, NightOutSpacing.md)

                        // Stats pills row
                        statsPillsRow
                            .padding(.top, NightOutSpacing.md)

                        Spacer()

                        // Quick action buttons
                        quickActionsCard
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)

                        // Bottom buttons (Add Drink + End)
                        bottomButtons
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)
                            .padding(.top, NightOutSpacing.md)
                            .padding(.bottom, NightOutSpacing.lg)
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
        .navigationTitle("Your Night")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                RecordingIndicator()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Show friends on map
                } label: {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(NightOutColors.electricBlue)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
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

    // MARK: - Map Background

    private var mapBackground: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {}
        .overlay(
            LinearGradient(
                colors: [
                    NightOutColors.background.opacity(0.9),
                    NightOutColors.background.opacity(0.3),
                    Color.clear,
                    NightOutColors.background.opacity(0.5),
                    NightOutColors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        EmptyView()
    }

    // MARK: - Stats Pills Row

    private var statsPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NightOutSpacing.sm) {
                StatPill(emoji: Emoji.distance, value: formattedDistance, label: "mi")
                StatPill(emoji: Emoji.drinks, value: "\(drinks.count)", label: "drinks")
                StatPill(emoji: Emoji.photos, value: "0", label: "pics")
                StatPill(emoji: Emoji.spots, value: "0", label: "spots")
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
        }
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        HStack(spacing: 0) {
            QuickActionItem(emoji: "📸🔥", label: "Photo") {
                showCamera = true
            }
            QuickActionItem(emoji: Emoji.songs, label: "Song") {
                showSongPicker = true
            }
            QuickActionItem(emoji: Emoji.sparkles, label: "Vibe") {
                showMoodPicker = true
            }
            QuickActionItem(emoji: Emoji.spots, label: "Spot") {
                showAddVenue = true
            }
        }
        .padding(.vertical, NightOutSpacing.sm)
        .background(NightOutColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: NightOutSpacing.md) {
            AddDrinkFAB {
                showAddDrink = true
            }

            MoonEndButton {
                showEndNight = true
            }
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
        guard let night else { return "0.0" }
        let miles = night.distance / 1609.34
        return String(format: "%.1f", miles)
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
        withAnimation(NightOutAnimation.pulse) {
            isPulsing = true
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item, let night else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
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
                    PrimaryGradientButton(title: "Take Photo", emoji: "📸") {
                        NightOutHaptics.medium()
                    }

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

// MARK: - Mood Level

enum MoodLevel: String, CaseIterable, Identifiable {
    case tired
    case okay
    case good
    case great
    case amazing

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .tired: return "😴"
        case .okay: return "😐"
        case .good: return "😊"
        case .great: return "😄"
        case .amazing: return "🤩"
        }
    }

    var displayName: String {
        switch self {
        case .tired: return "Tired"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        case .amazing: return "Amazing"
        }
    }
}

#Preview {
    NavigationStack {
        ActiveTrackingView()
    }
}
