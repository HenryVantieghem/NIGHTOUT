import SwiftUI
import CoreLocation

/// View to start a new night out - Strava-style with friend selection
@MainActor
struct StartNightView: View {
    let onNightStarted: () -> Void

    @State private var visibility: NightVisibility = .friends
    @State private var liveVisibility: LiveVisibility = .friends
    @State private var isStarting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentLocation: CLLocation?

    // Animation states
    @State private var showContent = false
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -30

    // Friend selection
    @State private var showFriendPicker = false
    @State private var selectedFriends: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(spacing: NightOutSpacing.xxl) {
                // Header with animated icon
                VStack(spacing: NightOutSpacing.md) {
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(NightOutColors.neonPink.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .blur(radius: 30)

                        // Moon icon
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(NightOutColors.primaryGradient)
                            .scaleEffect(iconScale)
                            .rotationEffect(.degrees(iconRotation))
                    }

                    Text("Start Your Night")
                        .font(NightOutTypography.title)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("Begin tracking your adventure")
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)
                }
                .padding(.top, NightOutSpacing.xxxl)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Who's with you section
                VStack(spacing: NightOutSpacing.lg) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(NightOutColors.neonPink)
                                Text("Who's With You?")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.chrome)

                                Spacer()

                                Text("Optional")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.dimmed)
                            }

                            if selectedFriends.isEmpty {
                                Button {
                                    showFriendPicker = true
                                    NightOutHaptics.light()
                                } label: {
                                    HStack(spacing: NightOutSpacing.sm) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(NightOutColors.neonPink)
                                        Text("Add Friends")
                                            .font(NightOutTypography.body)
                                            .foregroundStyle(NightOutColors.silver)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundStyle(NightOutColors.dimmed)
                                    }
                                    .padding(NightOutSpacing.md)
                                    .background(NightOutColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            } else {
                                HStack {
                                    // Show selected friends count
                                    HStack(spacing: -8) {
                                        ForEach(0..<min(3, selectedFriends.count), id: \.self) { index in
                                            Circle()
                                                .fill(LinearGradient(
                                                    colors: [NightOutColors.neonPink, NightOutColors.partyPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(.white)
                                                )
                                        }
                                        if selectedFriends.count > 3 {
                                            Circle()
                                                .fill(NightOutColors.surface)
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Text("+\(selectedFriends.count - 3)")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(NightOutColors.chrome)
                                                )
                                        }
                                    }

                                    Text("\(selectedFriends.count) friend\(selectedFriends.count == 1 ? "" : "s")")
                                        .font(NightOutTypography.subheadline)
                                        .foregroundStyle(NightOutColors.silver)

                                    Spacer()

                                    Button("Edit") {
                                        showFriendPicker = true
                                        NightOutHaptics.light()
                                    }
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.neonPink)
                                }
                            }
                        }
                    }

                    // Post visibility
                    GlassCard {
                        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                            HStack {
                                Image(systemName: "eye.fill")
                                    .foregroundStyle(NightOutColors.electricBlue)
                                Text("Post Visibility")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.chrome)
                            }

                            Text("Who can see your night when you post it")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            // Custom segmented control
                            HStack(spacing: NightOutSpacing.sm) {
                                ForEach(NightVisibility.allCases, id: \.self) { option in
                                    VisibilityOption(
                                        icon: option.icon,
                                        label: option.displayName,
                                        isSelected: visibility == option
                                    ) {
                                        visibility = option
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                    }

                    // Live visibility
                    GlassCard {
                        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                            HStack {
                                LiveIndicator()
                                Text("Live Location")
                                    .font(NightOutTypography.headline)
                                    .foregroundStyle(NightOutColors.chrome)
                            }

                            Text("Who can see your live location while out")
                                .font(NightOutTypography.caption)
                                .foregroundStyle(NightOutColors.silver)

                            HStack(spacing: NightOutSpacing.sm) {
                                ForEach(LiveVisibility.allCases, id: \.self) { option in
                                    LiveVisibilityOption(
                                        label: option.displayName,
                                        isSelected: liveVisibility == option
                                    ) {
                                        liveVisibility = option
                                        NightOutHaptics.light()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer(minLength: NightOutSpacing.xxl)

                // Start button with pulsing effect
                VStack(spacing: NightOutSpacing.md) {
                    GlassButton(
                        "Start Night",
                        icon: "play.fill",
                        style: .prominent,
                        size: .extraLarge,
                        isLoading: isStarting
                    ) {
                        Task { await startNight() }
                    }

                    Text("Your adventure begins now ✨")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
                .padding(.bottom, NightOutSpacing.xxl)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 40)
            }
        }
        .nightOutBackground()
        .navigationTitle("Track")
        .navigationBarTitleDisplayMode(.large)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showFriendPicker) {
            FriendPickerSheet(selectedFriends: $selectedFriends)
        }
        .onAppear {
            // Entrance animations
            withAnimation(NightOutAnimation.bouncy.delay(0.1)) {
                iconScale = 1.0
                iconRotation = 0
            }
            withAnimation(NightOutAnimation.smooth.delay(0.2)) {
                showContent = true
            }
        }
    }

    private func startNight() async {
        isStarting = true
        defer { isStarting = false }

        do {
            _ = try await NightService.shared.startNight(
                startLatitude: currentLocation?.coordinate.latitude,
                startLongitude: currentLocation?.coordinate.longitude,
                visibility: visibility,
                liveVisibility: liveVisibility
            )

            NightOutHaptics.success()
            onNightStarted()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            NightOutHaptics.error()
        }
    }
}

// MARK: - Visibility Option Button
@MainActor
struct VisibilityOption: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: NightOutSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(NightOutTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NightOutSpacing.md)
            .background(isSelected ? NightOutColors.neonPink.opacity(0.2) : NightOutColors.surface)
            .foregroundStyle(isSelected ? NightOutColors.neonPink : NightOutColors.silver)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.md)
                    .stroke(isSelected ? NightOutColors.neonPink : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Live Visibility Option
@MainActor
struct LiveVisibilityOption: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(NightOutTypography.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, NightOutSpacing.sm)
                .background(isSelected ? NightOutColors.liveRed.opacity(0.2) : NightOutColors.surface)
                .foregroundStyle(isSelected ? NightOutColors.liveRed : NightOutColors.silver)
                .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: NightOutRadius.sm)
                        .stroke(isSelected ? NightOutColors.liveRed : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Friend Picker Sheet
@MainActor
struct FriendPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFriends: Set<UUID>

    @State private var friends: [SupabaseProfile] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(NightOutColors.neonPink)
                        Spacer()
                    }
                } else if friends.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash",
                        title: "No Friends Yet",
                        message: "Add friends to share your nights with them"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: NightOutSpacing.sm) {
                            ForEach(friends, id: \.id) { friend in
                                FriendSelectionRow(
                                    friend: friend,
                                    isSelected: selectedFriends.contains(friend.id)
                                ) {
                                    if selectedFriends.contains(friend.id) {
                                        selectedFriends.remove(friend.id)
                                    } else {
                                        selectedFriends.insert(friend.id)
                                    }
                                    NightOutHaptics.light()
                                }
                            }
                        }
                        .padding(NightOutSpacing.screenHorizontal)
                    }
                }
            }
            .nightOutBackground()
            .navigationTitle("Who's With You?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.silver)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(NightOutColors.neonPink)
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await loadFriends()
        }
    }

    private func loadFriends() async {
        do {
            // Get friendships first
            let friendships = try await FriendshipService.shared.getFriends()

            // Fetch profile for each friend
            var loadedFriends: [SupabaseProfile] = []
            for friendship in friendships {
                if let profile = try? await UserService.shared.getProfile(userId: friendship.friendUserId) {
                    loadedFriends.append(profile)
                }
            }
            friends = loadedFriends
        } catch {
            print("Error loading friends: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Friend Selection Row
@MainActor
struct FriendSelectionRow: View {
    let friend: SupabaseProfile
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: NightOutSpacing.md) {
                // Avatar
                if let avatarUrl = friend.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(NightOutColors.surface)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [NightOutColors.neonPink, NightOutColors.partyPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(friend.displayName.prefix(1)))
                                .font(NightOutTypography.headline)
                                .foregroundStyle(.white)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("@\(friend.username)")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? NightOutColors.neonPink : NightOutColors.glassBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(NightOutColors.neonPink)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(NightOutSpacing.md)
            .background(isSelected ? NightOutColors.neonPink.opacity(0.1) : NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.md))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        StartNightView(onNightStarted: {})
    }
}
