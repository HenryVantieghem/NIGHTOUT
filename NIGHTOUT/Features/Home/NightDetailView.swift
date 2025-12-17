import SwiftUI
import MapKit

/// Detailed view of a single night
@MainActor
struct NightDetailView: View {
    let nightId: UUID

    @State private var night: SupabaseNight?
    @State private var profile: SupabaseProfile?
    @State private var isLoading = true
    @State private var hasLiked = false
    @State private var showReportSheet = false
    @State private var showShareSheet = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let night {
                ScrollView {
                    VStack(alignment: .leading, spacing: NightOutSpacing.lg) {
                        // Header card
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
                            }
                        }

                        // Stats card
                        GlassCard {
                            HStack {
                                ProfileStatItem(value: formattedDuration, label: "Duration", icon: "clock")
                                ProfileStatItem(value: formattedDistance, label: "Distance", icon: "figure.walk")
                                ProfileStatItem(value: "\(night.likeCount)", label: "Likes", icon: "heart")
                            }
                        }

                        // Map placeholder
                        if night.startLatitude != nil {
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

                        // Actions
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
        .toolbarBackground(NightOutColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
}

#Preview {
    NavigationStack {
        NightDetailView(nightId: UUID())
    }
}
