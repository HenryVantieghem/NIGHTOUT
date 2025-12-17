import SwiftUI
import Auth

/// Sheet to search and add friends
@MainActor
struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [SupabaseProfile] = []
    @State private var isSearching = false
    @State private var sentRequests: Set<UUID> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: NightOutSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NightOutColors.dimmed)

                    TextField("Search by username...", text: $searchText)
                        .foregroundStyle(NightOutColors.chrome)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(NightOutColors.dimmed)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                }
                .padding(NightOutSpacing.md)
                .background(NightOutColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.vertical, NightOutSpacing.md)

                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .tint(NightOutColors.neonPink)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "person.slash",
                        title: "No Users Found",
                        message: "Try searching with a different username"
                    )
                } else if searchText.isEmpty {
                    VStack(spacing: NightOutSpacing.lg) {
                        Spacer()
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(NightOutColors.dimmed)

                        Text("Search for friends")
                            .font(NightOutTypography.body)
                            .foregroundStyle(NightOutColors.silver)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: NightOutSpacing.sm) {
                            ForEach(searchResults) { profile in
                                SearchResultRow(
                                    profile: profile,
                                    hasSentRequest: sentRequests.contains(profile.id)
                                ) {
                                    sentRequests.insert(profile.id)
                                }
                            }
                        }
                        .padding(.horizontal, NightOutSpacing.screenHorizontal)
                        .padding(.vertical, NightOutSpacing.md)
                    }
                }
            }
            .nightOutBackground()
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(NightOutColors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
            }
            .onChange(of: searchText) { _, newValue in
                Task { await search(query: newValue) }
            }
        }
    }

    private func search(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await UserService.shared.searchProfiles(query: query, limit: 20)

            // Filter out current user
            if let currentUserId = SessionManager.shared.currentUser?.id {
                searchResults = searchResults.filter { $0.id != currentUserId }
            }
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }
    }
}

// MARK: - Search Result Row
@MainActor
struct SearchResultRow: View {
    let profile: SupabaseProfile
    let hasSentRequest: Bool
    let onRequestSent: () -> Void

    @State private var isSending = false
    @State private var friendshipStatus: FriendshipStatus?

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            AvatarView(
                url: profile.avatarUrl.flatMap { URL(string: $0) },
                name: profile.displayName,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                Text("@\(profile.username)")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)
            }

            Spacer()

            // Action button
            if friendshipStatus == .accepted {
                Text("Friends")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.successGreen)
                    .padding(.horizontal, NightOutSpacing.md)
                    .padding(.vertical, NightOutSpacing.xs)
                    .background(NightOutColors.successGreen.opacity(0.2))
                    .clipShape(Capsule())
            } else if friendshipStatus == .pending || hasSentRequest {
                Text("Pending")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.silver)
                    .padding(.horizontal, NightOutSpacing.md)
                    .padding(.vertical, NightOutSpacing.xs)
                    .background(NightOutColors.surface)
                    .clipShape(Capsule())
            } else {
                Button {
                    Task { await sendRequest() }
                } label: {
                    if isSending {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(NightOutColors.chrome)
                    } else {
                        Text("Add")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, NightOutSpacing.md)
                .padding(.vertical, NightOutSpacing.xs)
                .background(NightOutColors.neonPink)
                .clipShape(Capsule())
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .disabled(isSending)
            }
        }
        .padding(NightOutSpacing.md)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        .task {
            await checkFriendship()
        }
    }

    private func checkFriendship() async {
        do {
            friendshipStatus = try await FriendshipService.shared.getFriendshipStatus(with: profile.id)
        } catch {
            print("Error checking friendship: \(error)")
        }
    }

    private func sendRequest() async {
        isSending = true
        defer { isSending = false }

        do {
            try await FriendshipService.shared.sendRequest(to: profile.id)
            NightOutHaptics.success()
            onRequestSent()
        } catch {
            print("Error sending request: \(error)")
            NightOutHaptics.error()
        }
    }
}

#Preview {
    AddFriendView()
}
