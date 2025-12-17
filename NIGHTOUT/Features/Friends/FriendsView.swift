import SwiftUI

/// Friends list view
@MainActor
struct FriendsView: View {
    @State private var friends: [SupabaseFriendshipFull] = []
    @State private var pendingRequests: [SupabaseFriendshipFull] = []
    @State private var isLoading = true
    @State private var showAddFriend = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: NightOutSpacing.lg) {
                        // Pending requests
                        if !pendingRequests.isEmpty {
                            SectionHeader("Pending Requests", action: nil, actionTitle: nil)

                            ForEach(pendingRequests) { request in
                                FriendRequestRow(request: request) {
                                    Task { await loadData() }
                                }
                            }
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        }

                        // Friends list
                        SectionHeader("Friends (\(friends.count))")

                        if friends.isEmpty {
                            EmptyStateView(
                                icon: "person.2",
                                title: "No Friends Yet",
                                message: "Add friends to see their nights and share your adventures!",
                                actionTitle: "Add Friends"
                            ) {
                                showAddFriend = true
                            }
                        } else {
                            LazyVStack(spacing: NightOutSpacing.sm) {
                                ForEach(friends) { friend in
                                    FriendRow(friendship: friend)
                                }
                            }
                            .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        }
                    }
                    .padding(.vertical, NightOutSpacing.lg)
                }
                .refreshable {
                    await loadData()
                }
            }
        }
        .nightOutBackground()
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(NightOutColors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddFriend = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(NightOutColors.chrome)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendView()
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        do {
            friends = try await FriendshipService.shared.getFriends()
            pendingRequests = try await FriendshipService.shared.getPendingRequests()
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Friend Row
@MainActor
struct FriendRow: View {
    let friendship: SupabaseFriendshipFull
    @State private var profile: SupabaseProfile?

    var body: some View {
        NavigationLink {
            OtherUserProfileView(userId: friendship.friendUserId, username: profile?.username ?? "")
        } label: {
            HStack(spacing: NightOutSpacing.md) {
                AvatarView(
                    url: profile?.avatarUrl.flatMap { URL(string: $0) },
                    name: profile?.displayName ?? "Friend",
                    size: 44
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

                Image(systemName: "chevron.right")
                    .foregroundStyle(NightOutColors.dimmed)
            }
            .padding(NightOutSpacing.md)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        do {
            profile = try await UserService.shared.getProfile(userId: friendship.friendUserId)
        } catch {
            print("Error loading profile: \(error)")
        }
    }
}

// MARK: - Friend Request Row
@MainActor
struct FriendRequestRow: View {
    let request: SupabaseFriendshipFull
    let onAction: () -> Void

    @State private var profile: SupabaseProfile?
    @State private var isAccepting = false
    @State private var isRejecting = false

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            AvatarView(
                url: profile?.avatarUrl.flatMap { URL(string: $0) },
                name: profile?.displayName ?? "User",
                size: 44
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

            HStack(spacing: NightOutSpacing.sm) {
                Button {
                    Task { await reject() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(NightOutColors.silver)
                        .frame(width: 36, height: 36)
                        .background(NightOutColors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .disabled(isAccepting || isRejecting)

                Button {
                    Task { await accept() }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(NightOutColors.successGreen)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .disabled(isAccepting || isRejecting)
            }
        }
        .padding(NightOutSpacing.md)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        do {
            profile = try await UserService.shared.getProfile(userId: request.friendUserId)
        } catch {
            print("Error loading profile: \(error)")
        }
    }

    private func accept() async {
        isAccepting = true
        defer { isAccepting = false }

        do {
            try await FriendshipService.shared.acceptRequest(from: request.friendUserId)
            NightOutHaptics.success()
            onAction()
        } catch {
            print("Error accepting request: \(error)")
            NightOutHaptics.error()
        }
    }

    private func reject() async {
        isRejecting = true
        defer { isRejecting = false }

        do {
            try await FriendshipService.shared.rejectRequest(from: request.friendUserId)
            NightOutHaptics.light()
            onAction()
        } catch {
            print("Error rejecting request: \(error)")
            NightOutHaptics.error()
        }
    }
}

#Preview {
    NavigationStack {
        FriendsView()
    }
}
