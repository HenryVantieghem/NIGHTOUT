import SwiftUI

/// User profile view - Pixel-perfect redesign
@MainActor
struct ProfileView: View {
    @State private var profile: SupabaseProfile?
    @State private var nights: [SupabaseNight] = []
    @State private var friends: [SupabaseFriendshipFull] = []
    @State private var isLoading = true
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showFriends = false
    @State private var showAddFriend = false
    @State private var showAllNights = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProfileSkeletonView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.xl) {
                            // Profile header with avatar
                            profileHeader(profile: profile)

                            // Stats row
                            ProfileStatsRow(
                                nights: profile.totalNights,
                                friends: friends.count,
                                posts: nights.count
                            )
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)

                            // Edit profile button
                            EditProfileButton {
                                showEditProfile = true
                            }

                            // Your Nights section
                            nightsSection

                            Spacer(minLength: NightOutSpacing.tabBarTotal)
                        }
                        .padding(.top, NightOutSpacing.lg)
                    }
                    .refreshable {
                        await loadData()
                    }
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.exclamationmark",
                        title: "Profile Not Found",
                        message: "There was an error loading your profile."
                    )
                }
            }
            .nightOutBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(NightOutColors.chrome)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    EditProfileView(profile: profile)
                }
            }
            .sheet(isPresented: $showFriends) {
                ProfileFriendsListView()
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
            }
            .sheet(isPresented: $showAllNights) {
                AllNightsView(nights: nights)
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Profile Header

    private func profileHeader(profile: SupabaseProfile) -> some View {
        VStack(spacing: NightOutSpacing.md) {
            // Avatar with camera badge
            AvatarWithBadge(
                url: profile.avatarUrl.flatMap { URL(string: $0) },
                name: profile.displayName,
                size: 100,
                showCameraBadge: true
            )
            .contentShape(Circle())
            .onTapGesture {
                showEditProfile = true
            }

            // Username
            Text(profile.username)
                .font(NightOutTypography.title2)
                .foregroundStyle(NightOutColors.chrome)

            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(NightOutTypography.subheadline)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xxl)
            }
        }
    }

    // MARK: - Nights Section

    private var nightsSection: some View {
        VStack(spacing: NightOutSpacing.md) {
            // Section header
            UltraSectionHeader(
                title: "YOUR NIGHTS",
                rightText: nights.isEmpty ? nil : "See All",
                rightAction: nights.isEmpty ? nil : { showAllNights = true }
            )

            if nights.isEmpty {
                emptyNightsView
            } else {
                // Grid of nights
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(nights.prefix(4)) { night in
                        NavigationLink {
                            NightDetailView(nightId: night.id)
                        } label: {
                            NightGridCard(
                                duration: formatDuration(night.duration),
                                title: night.title ?? "Untitled",
                                date: formatDate(night.startTime)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
    }

    private var emptyNightsView: some View {
        VStack(spacing: NightOutSpacing.md) {
            Text(Emoji.moon)
                .font(.system(size: 48))

            Text("No nights yet")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.silver)

            Text("Start tracking to see your nights here!")
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.dimmed)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NightOutSpacing.xxxl)
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
    }

    // MARK: - Helpers

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func loadData() async {
        do {
            profile = try await UserService.shared.getCurrentProfile()
            nights = try await NightService.shared.getMyNights(limit: 20)
            friends = try await FriendshipService.shared.getFriends()
        } catch {
            print("Error loading profile: \(error)")
        }
        isLoading = false
    }
}

// MARK: - All Nights View

@MainActor
struct AllNightsView: View {
    @Environment(\.dismiss) private var dismiss
    let nights: [SupabaseNight]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(nights) { night in
                        NavigationLink {
                            NightDetailView(nightId: night.id)
                        } label: {
                            NightGridCard(
                                duration: formatDuration(night.duration),
                                title: night.title ?? "Untitled",
                                date: formatDate(night.startTime)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(NightOutSpacing.screenHorizontal)
            }
            .nightOutBackground()
            .navigationTitle("All Nights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.partyPurple)
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Profile Skeleton View

@MainActor
struct ProfileSkeletonView: View {
    var body: some View {
        VStack(spacing: NightOutSpacing.xl) {
            // Avatar placeholder
            Circle()
                .fill(NightOutColors.surface)
                .frame(width: 100, height: 100)

            // Username placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(NightOutColors.surface)
                .frame(width: 120, height: 24)

            // Bio placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(NightOutColors.surface)
                .frame(width: 200, height: 16)

            // Stats row placeholder
            HStack(spacing: NightOutSpacing.xxl) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: NightOutSpacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(NightOutColors.surface)
                            .frame(width: 40, height: 28)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(NightOutColors.surface)
                            .frame(width: 50, height: 12)
                    }
                }
            }

            Spacer()
        }
        .padding(.top, NightOutSpacing.xxxl)
    }
}

// MARK: - Profile Friends List View

@MainActor
struct ProfileFriendsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var friends: [SupabaseFriendshipFull] = []
    @State private var pendingRequests: [SupabaseFriendshipFull] = []
    @State private var profiles: [UUID: SupabaseProfile] = [:]
    @State private var isLoading = true
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    ProfileTabButton(title: "Friends (\(friends.count))", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    ProfileTabButton(title: "Requests (\(pendingRequests.count))", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.vertical, NightOutSpacing.sm)

                if isLoading {
                    LoadingView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: NightOutSpacing.sm) {
                            if selectedTab == 0 {
                                if friends.isEmpty {
                                    emptyFriendsView
                                } else {
                                    ForEach(friends) { friend in
                                        ProfileFriendListRow(
                                            friendship: friend,
                                            profile: profiles[friend.friendUserId],
                                            onRemove: {
                                                Task { await removeFriend(friend) }
                                            }
                                        )
                                    }
                                }
                            } else {
                                if pendingRequests.isEmpty {
                                    emptyRequestsView
                                } else {
                                    ForEach(pendingRequests) { request in
                                        ProfileFriendRequestListRow(
                                            friendship: request,
                                            profile: profiles[request.friendUserId],
                                            onAccept: {
                                                Task { await acceptRequest(request) }
                                            },
                                            onReject: {
                                                Task { await rejectRequest(request) }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.lg)
                    }
                }
            }
            .nightOutBackground()
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.partyPurple)
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private var emptyFriendsView: some View {
        VStack(spacing: NightOutSpacing.md) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundStyle(NightOutColors.dimmed)

            Text("No friends yet")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.silver)

            Text("Add friends to see their nights and track together!")
                .font(NightOutTypography.body)
                .foregroundStyle(NightOutColors.dimmed)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NightOutSpacing.xxl)
    }

    private var emptyRequestsView: some View {
        VStack(spacing: NightOutSpacing.md) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundStyle(NightOutColors.dimmed)

            Text("No pending requests")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NightOutSpacing.xxl)
    }

    private func loadData() async {
        do {
            friends = try await FriendshipService.shared.getFriends()
            pendingRequests = try await FriendshipService.shared.getPendingRequests()

            let allUserIds = Set(friends.map { $0.friendUserId } + pendingRequests.map { $0.friendUserId })
            for userId in allUserIds {
                if let profile = try? await UserService.shared.getProfile(userId: userId) {
                    profiles[userId] = profile
                }
            }
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }

    private func removeFriend(_ friend: SupabaseFriendshipFull) async {
        do {
            try await FriendshipService.shared.removeFriend(userId: friend.friendUserId)
            friends.removeAll { $0.id == friend.id }
            NightOutHaptics.success()
        } catch {
            print("Error removing friend: \(error)")
        }
    }

    private func acceptRequest(_ request: SupabaseFriendshipFull) async {
        do {
            try await FriendshipService.shared.acceptRequest(from: request.friendUserId)
            pendingRequests.removeAll { $0.id == request.id }
            friends = try await FriendshipService.shared.getFriends()
            NightOutHaptics.success()
        } catch {
            print("Error accepting request: \(error)")
        }
    }

    private func rejectRequest(_ request: SupabaseFriendshipFull) async {
        do {
            try await FriendshipService.shared.rejectRequest(from: request.friendUserId)
            pendingRequests.removeAll { $0.id == request.id }
            NightOutHaptics.light()
        } catch {
            print("Error rejecting request: \(error)")
        }
    }
}

// MARK: - Profile Tab Button

@MainActor
struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(NightOutTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
                .frame(maxWidth: .infinity)
                .padding(.vertical, NightOutSpacing.sm)
                .background(isSelected ? NightOutColors.neonPink.opacity(0.2) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? NightOutColors.neonPink : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Profile Friend List Row

@MainActor
struct ProfileFriendListRow: View {
    let friendship: SupabaseFriendshipFull
    let profile: SupabaseProfile?
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            AvatarView(
                url: profile?.avatarUrl.flatMap { URL(string: $0) },
                name: profile?.displayName ?? "Friend",
                size: 50
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.displayName ?? "Loading...")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Text("@\(profile?.username ?? "...")")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove Friend", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundStyle(NightOutColors.silver)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(NightOutSpacing.md)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Profile Friend Request List Row

@MainActor
struct ProfileFriendRequestListRow: View {
    let friendship: SupabaseFriendshipFull
    let profile: SupabaseProfile?
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            AvatarView(
                url: profile?.avatarUrl.flatMap { URL(string: $0) },
                name: profile?.displayName ?? "User",
                size: 50
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.displayName ?? "Loading...")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Text("@\(profile?.username ?? "...")")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)
            }

            Spacer()

            HStack(spacing: NightOutSpacing.sm) {
                Button {
                    onReject()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NightOutColors.silver)
                        .frame(width: 36, height: 36)
                        .background(NightOutColors.surfaceMedium)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())

                Button {
                    onAccept()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(NightOutColors.neonPink)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
            }
        }
        .padding(NightOutSpacing.md)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

#Preview {
    ProfileView()
}
