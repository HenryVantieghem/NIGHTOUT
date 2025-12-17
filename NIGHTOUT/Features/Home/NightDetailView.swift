import SwiftUI
import MapKit

/// Detailed view of a single night with comments
@MainActor
struct NightDetailView: View {
    let nightId: UUID

    @State private var night: SupabaseNight?
    @State private var profile: SupabaseProfile?
    @State private var drinks: [SupabaseDrink] = []
    @State private var photos: [SupabaseMedia] = []
    @State private var comments: [CommentWithAuthor] = []
    @State private var isLoading = true
    @State private var hasLiked = false
    @State private var showReportSheet = false
    @State private var showShareSheet = false
    @State private var newCommentText = ""
    @State private var isPostingComment = false

    // Real-time subscriptions
    private let realtimeManager = SupabaseRealtimeManager.shared

    var body: some View {
        Group {
            if isLoading {
                DetailSkeletonView()
            } else if let night {
                ScrollView {
                    VStack(alignment: .leading, spacing: NightOutSpacing.lg) {
                        // Header card
                        headerCard(night: night)

                        // Photos gallery
                        if !photos.isEmpty {
                            photosSection
                        }

                        // Stats card
                        statsCard(night: night)

                        // Drinks breakdown
                        if !drinks.isEmpty {
                            drinksSection
                        }

                        // Map
                        if night.startLatitude != nil {
                            mapSection
                        }

                        // Actions
                        actionsRow

                        // Comments section
                        commentsSection
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.vertical, NightOutSpacing.lg)
                }
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Night Not Found",
                    message: "This night may have been deleted or you don't have permission to view it."
                )
            }
        }
        .nightOutBackground()
        .navigationTitle("Night Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportSheet) {
            if let night {
                ReportContentView(
                    reportType: .night,
                    reportedUserId: night.userId,
                    nightId: night.id,
                    commentId: nil
                )
            }
        }
        .task {
            await loadNight()
            // Subscribe to real-time comments
            await realtimeManager.subscribeComments(for: nightId) { newComment in
                Task { @MainActor in
                    // Reload comments when new ones arrive
                    if let updatedComments = try? await CommentService.shared.getCommentsWithAuthors(nightId: nightId) {
                        comments = updatedComments
                    }
                }
            }
            // Subscribe to real-time reactions
            await realtimeManager.subscribeReactions(for: nightId) { _ in
                Task { @MainActor in
                    // Refresh like status and count
                    hasLiked = (try? await ReactionService.shared.hasLiked(nightId: nightId)) ?? hasLiked
                    if let updatedNight = try? await NightService.shared.getNight(id: nightId) {
                        night = updatedNight
                    }
                }
            }
        }
        .onDisappear {
            Task {
                await realtimeManager.unsubscribeAll()
            }
        }
    }

    // MARK: - Header Card

    private func headerCard(night: SupabaseNight) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                // User info
                HStack(spacing: NightOutSpacing.md) {
                    AvatarView(
                        url: profile?.avatarUrl.flatMap { URL(string: $0) },
                        name: profile?.displayName ?? "User",
                        size: 52
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile?.displayName ?? "Loading...")
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)

                        Text("@\(profile?.username ?? "")")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                    }

                    Spacer()

                    // Date
                    Text(dateText)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }

                // Title
                if let title = night.title, !title.isEmpty {
                    Text(title)
                        .font(NightOutTypography.title2)
                        .foregroundStyle(NightOutColors.chrome)
                }

                // Caption
                if let caption = night.caption, !caption.isEmpty {
                    Text(caption)
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                }

                // Venue
                if let venue = night.currentVenueName {
                    HStack(spacing: NightOutSpacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(NightOutColors.neonPink)
                        Text(venue)
                            .font(NightOutTypography.subheadline)
                            .foregroundStyle(NightOutColors.silver)
                    }
                }
            }
        }
    }

    // MARK: - Photos Section

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
            Text("Photos")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.chrome)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NightOutSpacing.sm) {
                    ForEach(photos) { photo in
                        AsyncImage(url: try? MediaService.shared.getPublicURL(path: photo.storagePath)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: NightOutRadius.md)
                                .fill(NightOutColors.surface)
                                .overlay {
                                    ProgressView()
                                        .tint(NightOutColors.neonPink)
                                }
                        }
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    }
                }
            }
        }
    }

    // MARK: - Stats Card

    private func statsCard(night: SupabaseNight) -> some View {
        GlassCard {
            HStack {
                DetailStatItem(value: formattedDuration, label: "Duration", icon: "clock.fill", color: NightOutColors.electricBlue)
                DetailStatItem(value: formattedDistance, label: "Distance", icon: "figure.walk", color: NightOutColors.successGreen)
                DetailStatItem(value: "\(drinks.count)", label: "Drinks", icon: "wineglass.fill", color: NightOutColors.neonPink)
                DetailStatItem(value: "\(night.likeCount)", label: "Likes", icon: "heart.fill", color: NightOutColors.liveRed)
            }
        }
    }

    // MARK: - Drinks Section

    private var drinksSection: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
            Text("Drinks")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.chrome)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NightOutSpacing.sm) {
                    ForEach(drinks) { drink in
                        let drinkType = DrinkType(rawValue: drink.type) ?? .custom
                        VStack(spacing: NightOutSpacing.xs) {
                            Text(drink.customEmoji ?? drinkType.emoji)
                                .font(.system(size: 32))
                            Text(drinkType.displayName)
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)
                        }
                        .padding(NightOutSpacing.sm)
                        .background(drinkType.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                    }
                }
            }
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
                Text("Route")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(NightOutColors.surface)
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "map")
                            .font(.system(size: 40))
                            .foregroundStyle(NightOutColors.dimmed)
                    }
            }
        }
    }

    // MARK: - Actions Row

    private var actionsRow: some View {
        HStack(spacing: NightOutSpacing.md) {
            GlassButton(
                hasLiked ? "Liked" : "Like",
                icon: hasLiked ? "heart.fill" : "heart",
                style: hasLiked ? .prominent : .secondary,
                size: .medium
            ) {
                toggleLike()
            }

            GlassButton("Share", icon: "square.and.arrow.up", style: .secondary, size: .medium) {
                showShareSheet = true
            }

            Spacer()

            Button {
                showReportSheet = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundStyle(NightOutColors.silver)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            HStack {
                Text("Comments")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Text("\(comments.count)")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)
                    .padding(.horizontal, NightOutSpacing.sm)
                    .padding(.vertical, 2)
                    .background(NightOutColors.surface)
                    .clipShape(Capsule())
            }

            // Comment input
            HStack(spacing: NightOutSpacing.sm) {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(GlassTextFieldStyle())

                Button {
                    Task { await postComment() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(newCommentText.isEmpty ? NightOutColors.dimmed : NightOutColors.neonPink)
                }
                .disabled(newCommentText.isEmpty || isPostingComment)
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            // Comments list
            if comments.isEmpty {
                Text("No comments yet. Be the first!")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NightOutSpacing.lg)
            } else {
                LazyVStack(spacing: NightOutSpacing.md) {
                    ForEach(comments) { item in
                        CommentRow(item: item)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var dateText: String {
        guard let night else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: night.startTime)
    }

    private var formattedDuration: String {
        guard let night else { return "0m" }
        let hours = night.duration / 3600
        let minutes = (night.duration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var formattedDistance: String {
        guard let night else { return "0m" }
        if night.distance >= 1000 {
            return String(format: "%.1f km", night.distance / 1000)
        }
        return String(format: "%.0f m", night.distance)
    }

    // MARK: - Actions

    private func loadNight() async {
        do {
            night = try await NightService.shared.getNight(id: nightId)
            if let userId = night?.userId {
                profile = try await UserService.shared.getProfile(userId: userId)
            }
            hasLiked = try await ReactionService.shared.hasLiked(nightId: nightId)
            drinks = try await DrinkService.shared.getDrinks(nightId: nightId)
            photos = try await MediaService.shared.getMedia(nightId: nightId)
            comments = try await CommentService.shared.getCommentsWithAuthors(nightId: nightId)
        } catch {
            print("Error loading night: \(error)")
        }
        isLoading = false
    }

    private func toggleLike() {
        Task {
            do {
                if hasLiked {
                    try await ReactionService.shared.unlikeNight(nightId: nightId)
                } else {
                    try await ReactionService.shared.likeNight(nightId: nightId)
                }
                hasLiked.toggle()
                NightOutHaptics.light()

                // Refresh night to get updated like count
                night = try await NightService.shared.getNight(id: nightId)
            } catch {
                print("Error toggling like: \(error)")
            }
        }
    }

    private func postComment() async {
        guard !newCommentText.isEmpty else { return }
        isPostingComment = true

        do {
            _ = try await CommentService.shared.addComment(nightId: nightId, text: newCommentText)
            newCommentText = ""
            comments = try await CommentService.shared.getCommentsWithAuthors(nightId: nightId)
            NightOutHaptics.success()
        } catch {
            print("Error posting comment: \(error)")
            NightOutHaptics.error()
        }

        isPostingComment = false
    }
}

// MARK: - Detail Stat Item
@MainActor
struct DetailStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(NightOutColors.dimmed)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Comment Row
@MainActor
struct CommentRow: View {
    let item: CommentWithAuthor

    var body: some View {
        HStack(alignment: .top, spacing: NightOutSpacing.sm) {
            AvatarView(
                url: item.author?.avatarUrl.flatMap { URL(string: $0) },
                name: item.author?.displayName ?? "User",
                size: 36
            )

            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                HStack {
                    Text(item.author?.displayName ?? "Unknown")
                        .font(NightOutTypography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(NightOutColors.chrome)

                    Text(timeAgo)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)

                    if item.comment.editedAt != nil {
                        Text("(edited)")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)
                    }
                }

                Text(item.comment.text)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            }

            Spacer()
        }
        .padding(NightOutSpacing.sm)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.comment.timestamp, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        NightDetailView(nightId: UUID())
    }
}
