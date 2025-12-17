import SwiftUI

/// User profile view
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

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProfileSkeletonView()
                } else if let profile {
                    ScrollView {
                        VStack(spacing: NightOutSpacing.lg) {
                            // Profile header
                            profileHeader(profile: profile)

                            // Stats row
                            statsCard(profile: profile)

                            // Friends section
                            friendsSection

                            // My nights section
                            nightsSection
                        }
                        .padding(.bottom, NightOutSpacing.xxl)
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
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Profile Header

    private func profileHeader(profile: SupabaseProfile) -> some View {
        VStack(spacing: NightOutSpacing.md) {
            // Avatar with gradient ring
            ZStack {
                Circle()
                    .stroke(NightOutColors.primaryGradient, lineWidth: 3)
                    .frame(width: 106, height: 106)

                AvatarView(
                    url: profile.avatarUrl.flatMap { URL(string: $0) },
                    name: profile.displayName,
                    size: 100
                )
            }

            VStack(spacing: NightOutSpacing.xs) {
                Text(profile.displayName)
                    .font(NightOutTypography.title2)
                    .foregroundStyle(NightOutColors.chrome)

                Text("@\(profile.username)")
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
            }

            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NightOutSpacing.xl)
            }

            GlassButton("Edit Profile", icon: "pencil", style: .secondary, size: .small) {
                showEditProfile = true
            }
        }
        .padding(.vertical, NightOutSpacing.lg)
    }

    // MARK: - Stats Card

    private func statsCard(profile: SupabaseProfile) -> some View {
        GlassCard {
            HStack {
                ProfileStatBox(value: profile.totalNights, label: "Nights")
                ProfileStatBox(value: friends.count, label: "Friends")
                ProfileStatBox(value: profile.currentStreak, label: "Streak")
            }
        }
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            HStack {
                Text("Friends")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Spacer()

                if !friends.isEmpty {
                    Button {
                        showFriends = true
                    } label: {
                        Text("See All")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.neonPink)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)

            if friends.isEmpty {
                GlassCard {
                    VStack(spacing: NightOutSpacing.md) {
                        Image(systemName: "person.2")
                            .font(.system(size: 32))
                            .foregroundStyle(NightOutColors.dimmed)

                        Text("No friends yet")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)

                        GlassButton("Add Friends", icon: "person.badge.plus", style: .primary, size: .small) {
                            showAddFriend = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NightOutSpacing.md)
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            } else {
                // Friends preview row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NightOutSpacing.md) {
                        // Add friend button
                        Button {
                            showAddFriend = true
                        } label: {
                            VStack(spacing: NightOutSpacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(NightOutColors.surface)
                                        .frame(width: 60, height: 60)

                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundStyle(NightOutColors.neonPink)
                                }

                                Text("Add")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.silver)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())

                        // Friend avatars
                        ForEach(friends.prefix(6)) { friend in
                            ProfileFriendAvatar(friendUserId: friend.friendUserId)
                        }
                    }
                    .padding(.horizontal, NightOutSpacing.screenHorizontal)
                }
            }
        }
    }

    // MARK: - Nights Section

    private var nightsSection: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            SectionHeader("My Nights")

            if nights.isEmpty {
                GlassCard {
                    VStack(spacing: NightOutSpacing.sm) {
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 32))
                            .foregroundStyle(NightOutColors.dimmed)

                        Text("No nights yet")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)

                        Text("Start tracking to see your nights here!")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NightOutSpacing.lg)
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            } else {
                LazyVStack(spacing: NightOutSpacing.md) {
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
            }
        }
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

// MARK: - Profile Stat Box

@MainActor
struct ProfileStatBox: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            Text("\(value)")
                .font(NightOutTypography.title2)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Friend Avatar

@MainActor
struct ProfileFriendAvatar: View {
    let friendUserId: UUID
    @State private var profile: SupabaseProfile?

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            AvatarView(
                url: profile?.avatarUrl.flatMap { URL(string: $0) },
                name: profile?.displayName ?? "Friend",
                size: 60
            )

            Text(profile?.displayName.prefix(8).description ?? "...")
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.silver)
                .lineLimit(1)
        }
        .task {
            profile = try? await UserService.shared.getProfile(userId: friendUserId)
        }
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
                    .foregroundStyle(NightOutColors.neonPink)
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
        GlassCard {
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
        }
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
        GlassCard {
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
                            .background(NightOutColors.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

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
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
