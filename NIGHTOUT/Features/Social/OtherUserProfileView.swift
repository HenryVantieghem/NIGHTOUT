//
//  OtherUserProfileView.swift
//  NIGHTOUT
//
//  View another user's profile (read-only)
//

import SwiftUI
import Supabase

struct OtherUserProfileView: View {
    let userId: UUID
    let username: String

    @Environment(\.dismiss) private var dismiss
    @State private var profile: SupabaseProfile?
    @State private var publicNights: [SupabaseNight] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isFriend = false
    @State private var friendshipPending = false
    @State private var isProcessingFriendship = false
    @State private var friendCount = 0

    private var isOwnProfile: Bool {
        SessionManager.shared.userId == userId
    }

    var body: some View {
        ZStack {
            NightOutColors.background.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(NightOutColors.partyPurple)
                    Text("Loading profile...")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("😕")
                        .font(.system(size: 60))
                    Text("Couldn't load profile")
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)
                    Text(error)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        Task { await loadProfile() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NightOutColors.partyPurple)
                }
                .padding()
            } else if let profile = profile {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            AsyncImage(url: profile.avatarUrl.flatMap { URL(string: $0) }) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        Text(Emoji.profile)
                                            .font(.system(size: 50))
                                    }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                            // Username & bio
                            VStack(spacing: 4) {
                                Text("@\(profile.username)")
                                    .font(NightOutTypography.title2)
                                    .foregroundStyle(NightOutColors.chrome)

                                if let bio = profile.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(NightOutTypography.body)
                                        .foregroundStyle(NightOutColors.silver)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            // Stats row
                            HStack(spacing: 32) {
                                ProfileStatItem(value: "\(profile.totalNights)", label: "Nights")
                                ProfileStatItem(value: "\(friendCount)", label: "Friends")
                                ProfileStatItem(value: "\(publicNights.count)", label: "Posts")
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)

                        // Friend action button (not shown on own profile)
                        if !isOwnProfile {
                            friendActionButton
                                .padding(.horizontal)
                        }

                        // Public nights
                        if !publicNights.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PUBLIC NIGHTS")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.dimmed)
                                    .padding(.horizontal)

                                LazyVStack(spacing: 12) {
                                    ForEach(publicNights, id: \.id) { night in
                                        OtherUserNightCard(night: night)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Text(Emoji.moon)
                                    .font(.system(size: 48))
                                Text("No public nights yet")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.silver)
                            }
                            .padding(.top, 40)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle(profile?.displayName ?? username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
            await loadPublicNights()
            await checkFriendshipStatus()
            await loadFriendCount()
        }
    }

    @ViewBuilder
    private var friendActionButton: some View {
        if isFriend {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(NightOutColors.successGreen)
                Text("Friends")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.successGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(NightOutColors.surface)
            }
        } else if friendshipPending {
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(NightOutColors.silver)
                Text("Request Pending")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .fill(NightOutColors.surface)
            }
        } else {
            Button(action: sendFriendRequest) {
                HStack(spacing: 8) {
                    if isProcessingFriendship {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                        Text("Add Friend")
                            .font(NightOutTypography.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: NightOutRadius.md)
                        .fill(NightOutColors.partyPurple)
                }
            }
            .disabled(isProcessingFriendship)
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            let userProfile = try await UserService.shared.getProfile(userId: userId)
            await MainActor.run {
                profile = userProfile
                errorMessage = nil
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func loadPublicNights() async {
        do {
            // Get public nights for this user
            let nights: [SupabaseNight] = try await supabase
                .from("nights")
                .select()
                .eq("user_id", value: userId)
                .eq("is_public", value: true)
                .eq("is_active", value: false)
                .order("start_time", ascending: false)
                .limit(20)
                .execute()
                .value

            await MainActor.run {
                publicNights = nights
            }
        } catch {
            print("Failed to load public nights: \(error.localizedDescription)")
        }
    }

    private func checkFriendshipStatus() async {
        guard SessionManager.shared.userId != nil else { return }

        do {
            let friendships = try await FriendshipService.shared.getFriendships()

            await MainActor.run {
                // Check if we're friends
                isFriend = friendships.contains { friendship in
                    friendship.status == "accepted" &&
                    (friendship.userId == userId || friendship.friendUserId == userId)
                }

                // Check if request is pending
                friendshipPending = friendships.contains { friendship in
                    friendship.status == "pending" &&
                    (friendship.friendUserId == userId || friendship.userId == userId)
                }
            }
        } catch {
            print("Failed to check friendship status: \(error.localizedDescription)")
        }
    }

    private func loadFriendCount() async {
        do {
            // Count accepted friendships for this user
            let count: Int = try await supabase
                .from("friendships")
                .select("*", head: true, count: .exact)
                .or("user_id.eq.\(userId),friend_user_id.eq.\(userId)")
                .eq("status", value: "accepted")
                .execute()
                .count ?? 0

            await MainActor.run {
                friendCount = count
            }
        } catch {
            print("Failed to load friend count: \(error.localizedDescription)")
        }
    }

    private func sendFriendRequest() {
        isProcessingFriendship = true
        NightOutHaptics.light()

        Task {
            do {
                try await FriendshipService.shared.sendRequest(to: userId)
                await MainActor.run {
                    friendshipPending = true
                    isProcessingFriendship = false
                    NightOutHaptics.success()
                }
            } catch {
                await MainActor.run {
                    isProcessingFriendship = false
                    NightOutHaptics.error()
                    print("Failed to send friend request: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Other User Night Card
struct OtherUserNightCard: View {
    let night: SupabaseNight

    private var formattedDuration: String {
        let hours = Int(night.duration) / 3600
        let minutes = (Int(night.duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: night.startTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text((night.title ?? "").isEmpty ? "Untitled Night" : (night.title ?? ""))
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Spacer()

                Text(formattedDate)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text(Emoji.time)
                        .font(.system(size: 14))
                    Text(formattedDuration)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }

                if let venueName = night.currentVenueName {
                    HStack(spacing: 4) {
                        Text(Emoji.location)
                            .font(.system(size: 14))
                        Text(venueName)
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.silver)
                            .lineLimit(1)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(NightOutColors.neonPink)
                    Text("\(night.likeCount)")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: NightOutRadius.md)
                .fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    NavigationStack {
        OtherUserProfileView(userId: UUID(), username: "testuser")
    }
}
