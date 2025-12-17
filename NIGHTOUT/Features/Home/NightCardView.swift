import SwiftUI

/// Card displaying a night summary in the feed
@MainActor
struct NightCardView: View {
    let night: SupabaseNight
    @State private var profile: SupabaseProfile?
    @State private var hasLiked = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                // Header: User info + time
                HStack(spacing: NightOutSpacing.md) {
                    // Avatar
                    AvatarView(
                        url: profile?.avatarUrl.flatMap { URL(string: $0) },
                        name: profile?.displayName ?? "User",
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile?.displayName ?? "Loading...")
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)

                        Text(timeAgoText)
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                    }

                    Spacer()

                    // Duration badge
                    HStack(spacing: NightOutSpacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(formattedDuration)
                            .font(NightOutTypography.caption)
                    }
                    .foregroundStyle(NightOutColors.silver)
                    .padding(.horizontal, NightOutSpacing.sm)
                    .padding(.vertical, NightOutSpacing.xs)
                    .background(NightOutColors.surface)
                    .clipShape(Capsule())
                }

                // Title and caption
                if let title = night.title, !title.isEmpty {
                    Text(title)
                        .font(NightOutTypography.title3)
                        .foregroundStyle(NightOutColors.chrome)
                }

                if let caption = night.caption, !caption.isEmpty {
                    Text(caption)
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                        .lineLimit(3)
                }

                // Stats row
                HStack(spacing: NightOutSpacing.lg) {
                    StatBadge(icon: "figure.walk", value: formattedDistance)
                    StatBadge(icon: "mappin", value: "\(night.currentVenueName ?? "0")")
                }

                // Actions row
                HStack(spacing: NightOutSpacing.lg) {
                    // Like button
                    Button {
                        toggleLike()
                    } label: {
                        HStack(spacing: NightOutSpacing.xs) {
                            Image(systemName: hasLiked ? "heart.fill" : "heart")
                                .foregroundStyle(hasLiked ? NightOutColors.liveRed : NightOutColors.silver)
                            Text("\(night.likeCount)")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    // Comment indicator
                    HStack(spacing: NightOutSpacing.xs) {
                        Image(systemName: "bubble.right")
                        Text("View")
                            .font(NightOutTypography.caption)
                    }
                    .foregroundStyle(NightOutColors.silver)

                    Spacer()

                    // Share button
                    Button {
                        // TODO: Share sheet
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(NightOutColors.silver)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.top, NightOutSpacing.sm)
            }
        }
        .task {
            await loadProfile()
            await checkLikeStatus()
        }
    }

    // MARK: - Computed Properties

    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: night.startTime, relativeTo: Date())
    }

    private var formattedDuration: String {
        let hours = night.duration / 3600
        let minutes = (night.duration % 3600) / 60
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

    private func loadProfile() async {
        do {
            profile = try await UserService.shared.getProfile(userId: night.userId)
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    private func checkLikeStatus() async {
        do {
            hasLiked = try await ReactionService.shared.hasLiked(nightId: night.id)
        } catch {
            print("Error checking like: \(error)")
        }
    }

    private func toggleLike() {
        Task {
            do {
                if hasLiked {
                    try await ReactionService.shared.unlikeNight(nightId: night.id)
                } else {
                    try await ReactionService.shared.likeNight(nightId: night.id)
                }
                hasLiked.toggle()
                NightOutHaptics.light()
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }
}

// MARK: - Stat Badge
@MainActor
struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: NightOutSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(NightOutTypography.caption)
        }
        .foregroundStyle(NightOutColors.silver)
    }
}

#Preview {
    NightCardView(night: SupabaseNight(
        id: UUID(),
        userId: UUID(),
        title: "Friday Night Out",
        caption: "Great night with the crew!",
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date(),
        duration: 7200,
        isActive: false,
        isPublic: true,
        visibility: "friends",
        liveVisibility: "friends",
        startLatitude: nil,
        startLongitude: nil,
        currentLatitude: nil,
        currentLongitude: nil,
        currentVenueName: "The Bar",
        distance: 2500,
        routePolyline: nil,
        likeCount: 5,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .padding()
    .background(NightOutColors.background)
}
