import SwiftUI
import MapKit
import Auth

/// Live map showing friends who are out with full social features
@MainActor
struct LiveView: View {
    @State private var liveFriends: [LiveFriendData] = []
    @State private var profiles: [UUID: SupabaseProfile] = [:]
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedFriend: LiveFriendData?
    @State private var isLoading = true
    @State private var showReactionMenu = false
    @State private var sheetDetent: PresentationDetent = .fraction(0.25)

    // Real-time subscriptions
    private let realtimeManager = SupabaseRealtimeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Main map
                mapLayer

                // Club atmosphere overlay
                ClubAtmosphere(intensity: .chill)
                    .opacity(0.3)
                    .allowsHitTesting(false)

                // Top controls
                VStack {
                    topControls
                    Spacer()
                }

                // Loading
                if isLoading {
                    MapSkeletonView()
                }

                // Selected friend card
                if let friend = selectedFriend {
                    VStack {
                        Spacer()
                        LiveFriendPeekCard(
                            friend: friend,
                            profile: profiles[friend.night.userId],
                            onViewProfile: { /* Navigate to profile */ },
                            onSendReaction: { showReactionMenu = true }
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .sheet(isPresented: .constant(true)) {
                friendsListSheet
                    .presentationDetents([.fraction(0.25), .fraction(0.5), .large], selection: $sheetDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showReactionMenu) {
                if let friend = selectedFriend {
                    LiveReactionSheet(friend: friend) { reaction in
                        sendReaction(reaction, to: friend)
                        showReactionMenu = false
                    }
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
                }
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadLiveFriends()
            // Subscribe to real-time friend location updates
            if let userId = SessionManager.shared.currentUser?.id {
                await realtimeManager.subscribeFriendLocations(for: userId)
            }
        }
        .onDisappear {
            // Cleanup subscriptions when leaving the view
            Task {
                await realtimeManager.unsubscribeAll()
            }
        }
        .onChange(of: realtimeManager.friendLocations) { _, newLocations in
            // Update live friends when real-time locations change
            updateFriendsFromRealtimeLocations(newLocations)
        }
    }

    // MARK: - Map Layer
    private var mapLayer: some View {
        Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) {
            // Friend markers
            ForEach(liveFriends) { friend in
                if let lat = friend.night.currentLatitude, let lon = friend.night.currentLongitude {
                    Annotation(profiles[friend.night.userId]?.displayName ?? "Friend", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                        LiveFriendMarker(
                            friend: friend,
                            profile: profiles[friend.night.userId],
                            isSelected: selectedFriend?.id == friend.id,
                            onTap: {
                                withAnimation(.spring(duration: 0.3)) {
                                    if selectedFriend?.id == friend.id {
                                        selectedFriend = nil
                                    } else {
                                        selectedFriend = friend
                                        position = .camera(MapCamera(
                                            centerCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                            distance: 1000,
                                            heading: 0,
                                            pitch: 45
                                        ))
                                    }
                                }
                            }
                        )
                    }
                }
            }

            // User location
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .colorScheme(.dark)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                withAnimation(.spring(duration: 0.3)) {
                    selectedFriend = nil
                }
            }
        )
    }

    // MARK: - Top Controls
    private var topControls: some View {
        HStack {
            // Live count badge
            HStack(spacing: 8) {
                Circle()
                    .fill(NightOutColors.liveRed)
                    .frame(width: 8, height: 8)
                    .beatPulse(intensity: 0.5, bpm: 120)

                Text("\(liveFriends.count) friend\(liveFriends.count == 1 ? "" : "s") live")
                    .font(NightOutTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(NightOutColors.chrome)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Refresh button
            Button {
                Task { await loadLiveFriends() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NightOutColors.chrome)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Circle())

            // Center on all button
            Button {
                centerOnAllFriends()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(NightOutColors.chrome)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }

    // MARK: - Friends List Sheet
    private var friendsListSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Friends Out Now")
                    .font(NightOutTypography.title3)
                    .foregroundStyle(NightOutColors.chrome)

                Spacer()

                // Live count
                HStack(spacing: 4) {
                    Circle()
                        .fill(NightOutColors.liveRed)
                        .frame(width: 6, height: 6)
                    Text("\(liveFriends.count)")
                        .font(NightOutTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(NightOutColors.liveRed)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(NightOutColors.liveRed.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .background(Color.white.opacity(0.1))

            // Friends list or empty state
            if liveFriends.isEmpty && !isLoading {
                VStack(spacing: NightOutSpacing.md) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 40))
                        .foregroundStyle(NightOutColors.dimmed)

                    Text("No friends out right now")
                        .font(NightOutTypography.body)
                        .foregroundStyle(NightOutColors.silver)

                    Text("When your friends start a night, they'll appear here!")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.dimmed)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NightOutSpacing.xxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(liveFriends) { friend in
                            LiveFriendListRow(
                                friend: friend,
                                profile: profiles[friend.night.userId],
                                isSelected: selectedFriend?.id == friend.id
                            ) {
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedFriend = friend
                                    if let lat = friend.night.currentLatitude, let lon = friend.night.currentLongitude {
                                        position = .camera(MapCamera(
                                            centerCoordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                                            distance: 1000,
                                            heading: 0,
                                            pitch: 45
                                        ))
                                    }
                                    sheetDetent = .fraction(0.25)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black)
    }

    // MARK: - Methods
    private func loadLiveFriends() async {
        guard let userId = SessionManager.shared.currentUser?.id else {
            isLoading = false
            return
        }

        do {
            let nights = try await NightService.shared.getLiveFriends(userId: userId)

            // Fetch profiles for all live friends
            var profileMap: [UUID: SupabaseProfile] = [:]
            for night in nights {
                if let profile = try? await UserService.shared.getProfile(userId: night.userId) {
                    profileMap[night.userId] = profile
                }
            }

            // Also fetch drink counts for each night
            var friendsData: [LiveFriendData] = []
            for night in nights {
                let drinkCount = (try? await DrinkService.shared.getDrinkCount(nightId: night.id)) ?? 0
                friendsData.append(LiveFriendData(night: night, drinkCount: drinkCount))
            }

            liveFriends = friendsData
            profiles = profileMap

            if !liveFriends.isEmpty {
                centerOnAllFriends()
            }
        } catch {
            print("Error loading live friends: \(error)")
        }

        isLoading = false
    }

    private func centerOnAllFriends() {
        guard !liveFriends.isEmpty else { return }

        let coords = liveFriends.compactMap { friend -> CLLocationCoordinate2D? in
            guard let lat = friend.night.currentLatitude, let lon = friend.night.currentLongitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }

        guard !coords.isEmpty else { return }

        let minLat = coords.map { $0.latitude }.min() ?? 0
        let maxLat = coords.map { $0.latitude }.max() ?? 0
        let minLon = coords.map { $0.longitude }.min() ?? 0
        let maxLon = coords.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5 + 0.01,
            longitudeDelta: (maxLon - minLon) * 1.5 + 0.01
        )

        withAnimation(.spring(duration: 0.5)) {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }

    private func sendReaction(_ reaction: String, to friend: LiveFriendData) {
        NightOutHaptics.success()

        Task {
            do {
                try await ReactionService.shared.sendReaction(
                    toUserId: friend.night.userId,
                    emoji: reaction,
                    type: "map_ping"
                )
                print("✅ Sent \(reaction) to friend")
            } catch {
                print("⚠️ Failed to send reaction: \(error.localizedDescription)")
            }
        }
    }

    private func updateFriendsFromRealtimeLocations(_ locations: [FriendLocation]) {
        // Update existing friends with real-time location data
        for location in locations {
            if let index = liveFriends.firstIndex(where: { $0.night.userId == location.userId }) {
                // Create updated night with new location
                var updatedNight = liveFriends[index].night
                // Note: We'd need to update the night's location fields
                // For now, we'll refetch to get the latest data
            }
        }

        // If we have new locations, refetch to sync
        if !locations.isEmpty {
            Task {
                await loadLiveFriends()
            }
        }
    }
}

// MARK: - Live Friend Data
struct LiveFriendData: Identifiable {
    let night: SupabaseNight
    let drinkCount: Int

    var id: UUID { night.id }
}

// MARK: - Live Friend Marker
@MainActor
struct LiveFriendMarker: View {
    let friend: LiveFriendData
    let profile: SupabaseProfile?
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Pulse rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(NightOutColors.liveRed.opacity(0.4 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 50 + CGFloat(index * 15), height: 50 + CGFloat(index * 15))
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                }

                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [NightOutColors.neonPink.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)

                // Avatar container
                ZStack {
                    Circle()
                        .fill(NightOutColors.liveRed)
                        .frame(width: 48, height: 48)

                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    // Avatar
                    if let avatarUrl = profile?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(NightOutColors.chrome)
                    }
                }
                .shadow(color: NightOutColors.neonPink.opacity(0.5), radius: 8)

                // Live badge
                Circle()
                    .fill(NightOutColors.liveRed)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
                    .offset(x: 16, y: -16)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(duration: 0.3), value: isSelected)

            // Name label (when selected)
            if isSelected {
                VStack(spacing: 2) {
                    Text(profile?.displayName ?? "Friend")
                        .font(NightOutTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(NightOutColors.chrome)

                    if let venue = friend.night.currentVenueName {
                        Text("@ \(venue)")
                            .font(NightOutTypography.caption2)
                            .foregroundStyle(NightOutColors.silver)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NightOutHaptics.light()
            onTap()
        }
        .onAppear {
            startPulseAnimation()
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 2.0
            pulseOpacity = 0
        }
    }
}

// MARK: - Live Friend List Row
@MainActor
struct LiveFriendListRow: View {
    let friend: LiveFriendData
    let profile: SupabaseProfile?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(NightOutColors.neonPink.opacity(0.2))
                        .frame(width: 46, height: 46)

                    if let avatarUrl = profile?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)
                        }
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                    } else {
                        Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(NightOutColors.chrome)
                    }

                    // Live indicator
                    Circle()
                        .fill(NightOutColors.liveRed)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .stroke(.black, lineWidth: 2)
                        }
                        .offset(x: 16, y: -16)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(profile?.displayName ?? "Friend")
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)

                        Text("LIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(NightOutColors.liveRed)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(NightOutColors.liveRed.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        if let venue = friend.night.currentVenueName {
                            HStack(spacing: 3) {
                                Text("📍")
                                    .font(.system(size: 10))
                                Text(venue)
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.silver)
                                    .lineLimit(1)
                            }
                        }

                        if friend.drinkCount > 0 {
                            HStack(spacing: 3) {
                                Text("🍺")
                                    .font(.system(size: 10))
                                Text("\(friend.drinkCount)")
                                    .font(NightOutTypography.caption)
                                    .foregroundStyle(NightOutColors.silver)
                            }
                        }
                    }
                }

                Spacer()

                // Duration
                let duration = Int(Date().timeIntervalSince(friend.night.startTime))
                let hours = duration / 3600
                let minutes = (duration % 3600) / 60
                Text(hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.dimmed)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NightOutColors.dimmed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? NightOutColors.partyPurple.opacity(0.15) : .clear)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Live Friend Peek Card
@MainActor
struct LiveFriendPeekCard: View {
    let friend: LiveFriendData
    let profile: SupabaseProfile?
    let onViewProfile: () -> Void
    let onSendReaction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            // Header
            HStack(spacing: NightOutSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(NightOutColors.neonPink.opacity(0.2))
                        .frame(width: 50, height: 50)

                    if let avatarUrl = profile?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                                .font(NightOutTypography.headline)
                                .foregroundStyle(NightOutColors.chrome)
                        }
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                    } else {
                        Text(profile?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(NightOutColors.chrome)
                    }

                    // Live badge
                    Circle()
                        .fill(NightOutColors.liveRed)
                        .frame(width: 12, height: 12)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                        .offset(x: 18, y: -18)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile?.displayName ?? "Friend")
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("@\(profile?.username ?? "")")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(NightOutColors.liveRed)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(NightOutTypography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(NightOutColors.liveRed)
                    }
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: NightOutSpacing.lg) {
                if let venue = friend.night.currentVenueName {
                    LiveStatPill(emoji: "📍", value: venue)
                }

                if friend.drinkCount > 0 {
                    LiveStatPill(emoji: "🍺", value: "\(friend.drinkCount)")
                }

                // Duration
                let duration = Int(Date().timeIntervalSince(friend.night.startTime))
                let hours = duration / 3600
                let minutes = (duration % 3600) / 60
                LiveStatPill(emoji: "⏱️", value: hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
            }

            // Action buttons
            HStack(spacing: NightOutSpacing.md) {
                Button(action: onSendReaction) {
                    HStack(spacing: 6) {
                        Text("🍻")
                        Text("Cheers!")
                            .font(NightOutTypography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(NightOutColors.chrome)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(NightOutColors.partyPurple.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(NightOutColors.partyPurple.opacity(0.5), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())

                Button(action: onViewProfile) {
                    Text("View")
                        .font(NightOutTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(NightOutColors.silver)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
            }
        }
        .padding(NightOutSpacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: NightOutRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: NightOutColors.neonPink.opacity(0.3), radius: 20)
    }
}

// MARK: - Live Stat Pill
@MainActor
struct LiveStatPill: View {
    let emoji: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))
            Text(value)
                .font(NightOutTypography.caption2)
                .foregroundStyle(NightOutColors.silver)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(NightOutColors.surface)
        .clipShape(Capsule())
    }
}

// MARK: - Live Reaction Sheet
@MainActor
struct LiveReactionSheet: View {
    let friend: LiveFriendData
    let onReact: (String) -> Void

    let reactions = [
        ("🍻", "Cheers!"),
        ("🚗", "On my way!"),
        ("🔥", "Fire!"),
        ("👀", "Coming!"),
        ("⚡", "Vibe check")
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Send reaction")
                .font(NightOutTypography.headline)
                .foregroundStyle(NightOutColors.chrome)

            HStack(spacing: 16) {
                ForEach(reactions, id: \.0) { emoji, label in
                    Button {
                        onReact(emoji)
                    } label: {
                        VStack(spacing: 6) {
                            Text(emoji)
                                .font(.system(size: 32))
                            Text(label)
                                .font(NightOutTypography.caption2)
                                .foregroundStyle(NightOutColors.silver)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding()
        .background(Color.black)
    }
}

#Preview {
    LiveView()
}
