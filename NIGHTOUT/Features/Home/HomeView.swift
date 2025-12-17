import SwiftUI
import Auth

/// Home feed showing friends' nights
@MainActor
struct HomeView: View {
    @State private var nights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedFilter: FeedFilter = .all
    @State private var showAddFriends = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs
                filterTabs
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                    .padding(.vertical, NightOutSpacing.sm)

                // Content
                Group {
                    if isLoading {
                        FeedSkeletonView()
                    } else if nights.isEmpty {
                        emptyState
                    } else {
                        feedList
                    }
                }
            }
            .nightOutBackground()
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddFriends = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(NightOutColors.neonPink)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showAddFriends) {
                AddFriendView()
            }
        }
        .task {
            await loadFeed()
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: NightOutSpacing.sm) {
            ForEach(FeedFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                    NightOutHaptics.light()
                    Task { await loadFeed() }
                } label: {
                    Text(filter.displayName)
                        .font(NightOutTypography.subheadline)
                        .fontWeight(selectedFilter == filter ? .semibold : .regular)
                        .foregroundStyle(selectedFilter == filter ? NightOutColors.chrome : NightOutColors.silver)
                        .padding(.horizontal, NightOutSpacing.md)
                        .padding(.vertical, NightOutSpacing.sm)
                        .background(selectedFilter == filter ? NightOutColors.neonPink.opacity(0.2) : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedFilter == filter ? NightOutColors.neonPink : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: NightOutSpacing.lg) {
            Spacer()

            VStack(spacing: NightOutSpacing.md) {
                ZStack {
                    Circle()
                        .fill(NightOutColors.neonPink.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)

                    Image(systemName: "moon.stars")
                        .font(.system(size: 56))
                        .foregroundStyle(NightOutColors.primaryGradient)
                }

                Text("No Nights Yet")
                    .font(NightOutTypography.title2)
                    .foregroundStyle(NightOutColors.chrome)

                Text("Add friends to see their nights here, or start your own adventure!")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xxl)
            }

            GlassButton("Find Friends", icon: "person.2.fill", style: .primary, size: .large) {
                showAddFriends = true
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)

            Spacer()
        }
    }

    // MARK: - Feed List

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: NightOutSpacing.lg) {
                ForEach(nights) { night in
                    NavigationLink {
                        NightDetailView(nightId: night.id)
                    } label: {
                        NightCardView(night: night)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.vertical, NightOutSpacing.lg)
        }
        .refreshable {
            await loadFeed()
        }
    }

    // MARK: - Actions

    private func loadFeed() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            switch selectedFilter {
            case .all:
                nights = try await NightService.shared.getFeed(userId: userId, limit: 50)
            case .following:
                nights = try await NightService.shared.getFriendsFeed(userId: userId, limit: 50)
            case .highlights:
                nights = try await NightService.shared.getHighlights(limit: 20)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}

// MARK: - Feed Filter
enum FeedFilter: String, CaseIterable {
    case all = "all"
    case following = "following"
    case highlights = "highlights"

    var displayName: String {
        switch self {
        case .all: return "All"
        case .following: return "Following"
        case .highlights: return "Highlights"
        }
    }
}

#Preview {
    HomeView()
}
