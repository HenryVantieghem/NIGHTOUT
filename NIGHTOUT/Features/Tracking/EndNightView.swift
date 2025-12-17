import SwiftUI

/// Sheet to end night and create post
@MainActor
struct EndNightView: View {
    @Environment(\.dismiss) private var dismiss
    let night: SupabaseNight

    @State private var title = ""
    @State private var caption = ""
    @State private var isPublic = true
    @State private var isEnding = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NightOutSpacing.xxl) {
                    // Summary stats
                    GlassCard {
                        VStack(spacing: NightOutSpacing.md) {
                            Text("Night Summary")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)

                            HStack {
                                ProfileStatItem(
                                    value: formattedDuration,
                                    label: "Duration",
                                    icon: "clock"
                                )
                                ProfileStatItem(
                                    value: formattedDistance,
                                    label: "Distance",
                                    icon: "figure.walk"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    // Post form
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

                        // Public toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Post to Feed")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.chrome)

                                Text("Share with your friends")
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
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)

                    Spacer(minLength: NightOutSpacing.xxl)

                    // End button
                    VStack(spacing: NightOutSpacing.md) {
                        GlassButton(
                            "End & Post Night",
                            icon: "checkmark.circle",
                            style: .primary,
                            size: .large,
                            isLoading: isEnding
                        ) {
                            Task { await endNight() }
                        }

                        Button("Discard Night") {
                            // TODO: Confirm and delete
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
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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

            NightOutHaptics.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

#Preview {
    EndNightView(night: SupabaseNight(
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
        currentVenueName: nil,
        distance: 2500,
        routePolyline: nil,
        likeCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    ))
}
