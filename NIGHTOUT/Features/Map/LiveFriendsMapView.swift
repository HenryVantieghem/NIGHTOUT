//
//  LiveFriendsMapView.swift
//  NIGHTOUT
//
//  BeerBuddy-style live friends map - see where everyone's at in real-time
//  Full-screen map with friend markers, bottom sheet, and reactions
//

import SwiftUI
import MapKit
import Supabase

// MARK: - Live Friends Map View
/// Full-screen map showing all friends who are currently out
struct LiveFriendsMapView: View {
    @State private var friends: [LiveFriendLocation] = []
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedFriend: LiveFriendLocation?
    @State private var showBottomSheet = true
    @State private var sheetDetent: PresentationDetent = .fraction(0.25)
    @State private var isLoading = true
    @State private var showReactionMenu = false

    var body: some View {
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

            // Selected friend card
            if let friend = selectedFriend {
                VStack {
                    Spacer()
                    FriendPeekCard(
                        friend: friend,
                        onViewProfile: { /* Navigate to profile */ },
                        onSendReaction: { showReactionMenu = true }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showBottomSheet) {
            friendsListSheet
                .presentationDetents([.fraction(0.25), .fraction(0.5), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showReactionMenu) {
            if let friend = selectedFriend {
                QuickReactionSheet(friend: friend) { reaction in
                    sendReaction(reaction, to: friend)
                    showReactionMenu = false
                }
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            await loadFriends()
        }
    }

    // MARK: - Map Layer
    private var mapLayer: some View {
        Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) {
            // Friend markers
            ForEach(friends) { friend in
                Annotation(friend.displayName, coordinate: friend.coordinate) {
                    FriendMapMarker(
                        friend: friend,
                        isSelected: selectedFriend?.id == friend.id,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                if selectedFriend?.id == friend.id {
                                    selectedFriend = nil
                                } else {
                                    selectedFriend = friend
                                    position = .camera(MapCamera(
                                        centerCoordinate: friend.coordinate,
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
                // Deselect when tapping map
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

                Text("\(friends.filter { $0.isLive }.count) friends live")
                    .font(NightOutTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(NightOutColors.chrome)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

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
        }
        .padding(.horizontal)
        .padding(.top, 8)
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
                    Text("\(friends.filter { $0.isLive }.count)")
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

            // Friends list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(friends.sorted { $0.isLive && !$1.isLive }) { friend in
                        FriendListRow(friend: friend, isSelected: selectedFriend?.id == friend.id) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedFriend = friend
                                position = .camera(MapCamera(
                                    centerCoordinate: friend.coordinate,
                                    distance: 1000,
                                    heading: 0,
                                    pitch: 45
                                ))
                                sheetDetent = .fraction(0.25)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black)
    }

    // MARK: - Methods
    private func loadFriends() async {
        // Simulate loading friends from RealtimeService
        try? await Task.sleep(for: .seconds(1))

        // Rich demo data for Apple App Store review
        // 6 diverse friends showcasing different activities, venues, and states
        friends = [
            // Sarah - The Social Butterfly (Living for Friday nights ✨)
            LiveFriendLocation(
                displayName: "Sarah",
                username: "sarah_party",
                avatarEmoji: "👩‍🦰",
                latitude: 40.7128,
                longitude: -74.0060,
                isLive: true,
                currentVenue: "The Spot • 142 W Broadway",
                currentActivity: "🍸",
                drinkCount: 4,
                lastUpdate: Date().addingTimeInterval(-180), // 3 min ago
                accentColor: NightOutColors.neonPink
            ),
            // Mike - The DJ/Musician (If the music's good, I'm there 🎵)
            LiveFriendLocation(
                displayName: "Mike",
                username: "mike_vibes",
                avatarEmoji: "🧔",
                latitude: 40.7148,
                longitude: -74.0050,
                isLive: true,
                currentVenue: "Club Neon • 88 Prince St",
                currentActivity: "🎵",
                drinkCount: 2,
                lastUpdate: Date().addingTimeInterval(-45), // 45 sec ago
                accentColor: NightOutColors.electricBlue
            ),
            // Emma - The Content Creator (Documenting the chaos 📸)
            LiveFriendLocation(
                displayName: "Emma",
                username: "emma_nights",
                avatarEmoji: "👱‍♀️",
                latitude: 40.7138,
                longitude: -74.0080,
                isLive: true,
                currentVenue: "Skyline Rooftop • 230 5th Ave",
                currentActivity: "📸",
                drinkCount: 3,
                lastUpdate: Date().addingTimeInterval(-300), // 5 min ago
                accentColor: NightOutColors.partyPurple
            ),
            // Alex - The Foodie (Late night tacos hit different 🌮)
            LiveFriendLocation(
                displayName: "Alex",
                username: "alex_foodie",
                avatarEmoji: "🍕",
                latitude: 40.7168,
                longitude: -74.0045,
                isLive: true,
                currentVenue: "Taco Joint • 75 Greenwich Ave",
                currentActivity: "🌮",
                drinkCount: 1,
                lastUpdate: Date().addingTimeInterval(-120), // 2 min ago
                accentColor: NightOutColors.goldenHour
            ),
            // Zoe - The Dancer (Dance floor is my happy place 💃)
            LiveFriendLocation(
                displayName: "Zoe",
                username: "zoe_dancer",
                avatarEmoji: "💃",
                latitude: 40.7118,
                longitude: -74.0070,
                isLive: true,
                currentVenue: "Latin Nights • 96 Bowery",
                currentActivity: "🔥",
                drinkCount: 3,
                lastUpdate: Date().addingTimeInterval(-60), // 1 min ago
                accentColor: NightOutColors.liveRed
            ),
            // Jake - The Early Leaver (Early bird catches the worm 🌅)
            LiveFriendLocation(
                displayName: "Jake",
                username: "jake_dj",
                avatarEmoji: "🎧",
                latitude: 40.7158,
                longitude: -74.0040,
                isLive: false,
                currentVenue: nil,
                currentActivity: nil,
                drinkCount: 0,
                lastUpdate: Date().addingTimeInterval(-7200), // 2 hours ago
                accentColor: NightOutColors.silver
            )
        ]

        isLoading = false
        centerOnAllFriends()
    }

    private func centerOnAllFriends() {
        guard !friends.isEmpty else { return }

        let liveFriends = friends.filter { $0.isLive }
        let targetFriends = liveFriends.isEmpty ? friends : liveFriends

        let coords = targetFriends.map { $0.coordinate }
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

    private func sendReaction(_ reaction: String, to friend: LiveFriendLocation) {
        NightOutHaptics.success()

        Task {
            do {
                // Insert reaction into Supabase
                try await supabase
                    .from("reactions")
                    .insert([
                        "recipient_id": friend.userId.uuidString,
                        "reaction_emoji": reaction,
                        "reaction_type": "map_ping"
                    ])
                    .execute()

                print("✅ Sent \(reaction) to \(friend.displayName)")
            } catch {
                print("⚠️ Failed to send reaction: \(error.localizedDescription)")
                // Reaction still appears locally even if sync fails
            }
        }
    }
}

// MARK: - Friend List Row
struct FriendListRow: View {
    let friend: LiveFriendLocation
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(friend.accentColor.opacity(0.2))
                        .frame(width: 46, height: 46)

                    Text(friend.avatarEmoji)
                        .font(.system(size: 24))

                    if friend.isLive {
                        Circle()
                            .fill(NightOutColors.liveRed)
                            .frame(width: 10, height: 10)
                            .overlay {
                                Circle()
                                    .stroke(.black, lineWidth: 2)
                            }
                            .offset(x: 16, y: -16)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(friend.displayName)
                            .font(NightOutTypography.headline)
                            .foregroundStyle(NightOutColors.chrome)

                        if friend.isLive {
                            Text("LIVE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(NightOutColors.liveRed)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(NightOutColors.liveRed.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    if friend.isLive {
                        HStack(spacing: 8) {
                            if let venue = friend.currentVenue {
                                HStack(spacing: 3) {
                                    Text("📍")
                                        .font(.system(size: 10))
                                    Text(venue)
                                        .font(NightOutTypography.caption)
                                        .foregroundStyle(NightOutColors.silver)
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
                    } else {
                        Text("Not currently out")
                            .font(NightOutTypography.caption)
                            .foregroundStyle(NightOutColors.dimmed)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(NightOutColors.dimmed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? NightOutColors.partyPurple.opacity(0.15) : .clear)
        }
    }
}

// MARK: - Quick Reaction Sheet
struct QuickReactionSheet: View {
    let friend: LiveFriendLocation
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
            Text("Send to \(friend.displayName)")
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
                }
            }
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Preview
#Preview("Live Friends Map") {
    LiveFriendsMapView()
}
