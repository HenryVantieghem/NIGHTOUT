import SwiftUI

/// Card displaying a night summary in the feed
@MainActor
struct NightCardView: View {
    let night: SupabaseNight
    @State private var profile: SupabaseProfile?
    @State private var hasLiked = false
    @State private var commentCount = 0
    @State private var drinkCount = 0
    @State private var photos: [SupabaseMedia] = []
    @State private var likeCount: Int

    init(night: SupabaseNight) {
        self.night = night
        self._likeCount = State(initialValue: night.likeCount)
    }

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

                // Photo preview
                if !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: NightOutSpacing.sm) {
                            ForEach(photos.prefix(4)) { photo in
                                AsyncImage(url: try? MediaService.shared.getPublicURL(path: photo.storagePath)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: NightOutRadius.sm)
                                        .fill(NightOutColors.surface)
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.sm))
                            }

                            if photos.count > 4 {
                                ZStack {
                                    RoundedRectangle(cornerRadius: NightOutRadius.sm)
                                        .fill(NightOutColors.surface)
                                    Text("+\(photos.count - 4)")
                                        .font(NightOutTypography.headline)
                                        .foregroundStyle(NightOutColors.chrome)
                                }
                                .frame(width: 80, height: 80)
                            }
                        }
                    }
                }

                // Stats row
                HStack(spacing: NightOutSpacing.lg) {
                    FeedStatBadge(icon: "figure.walk", value: formattedDistance)

                    if drinkCount > 0 {
                        FeedStatBadge(icon: "wineglass.fill", value: "\(drinkCount)")
                    }

                    if let venue = night.currentVenueName {
                        FeedStatBadge(icon: "mappin", value: venue)
                    }
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
                            Text("\(likeCount)")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                        }
                        .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    // Comment indicator
                    HStack(spacing: NightOutSpacing.xs) {
                        Image(systemName: "bubble.right")
                        Text("\(commentCount)")
                            .font(NightOutTypography.caption)
                    }
                    .foregroundStyle(NightOutColors.silver)

                    Spacer()

                    // Share button
                    Button {
                        shareNight()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(NightOutColors.silver)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.top, NightOutSpacing.sm)
            }
        }
        .task {
            await loadData()
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

    private func loadData() async {
        do {
            profile = try await UserService.shared.getProfile(userId: night.userId)
            hasLiked = try await ReactionService.shared.hasLiked(nightId: night.id)
            commentCount = try await CommentService.shared.getCommentCount(nightId: night.id)
            drinkCount = try await DrinkService.shared.getDrinkCount(nightId: night.id)
            photos = try await MediaService.shared.getMedia(nightId: night.id)
        } catch {
            print("Error loading card data: \(error)")
        }
    }

    private func toggleLike() {
        Task {
            do {
                if hasLiked {
                    try await ReactionService.shared.unlikeNight(nightId: night.id)
                    likeCount -= 1
                } else {
                    try await ReactionService.shared.likeNight(nightId: night.id)
                    likeCount += 1
                }
                hasLiked.toggle()
                NightOutHaptics.light()
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }

    private func shareNight() {
        // TODO: Implement share sheet
        NightOutHaptics.light()
    }
}

// MARK: - Feed Stat Badge
@MainActor
struct FeedStatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: NightOutSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(value)
                .font(NightOutTypography.caption)
                .lineLimit(1)
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
