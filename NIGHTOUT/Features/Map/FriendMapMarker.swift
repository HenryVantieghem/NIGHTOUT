//
//  FriendMapMarker.swift
//  NIGHTOUT
//
//  Animated avatar markers for friends on the live map
//  BeerBuddy-style friend visualization with party vibes
//

import SwiftUI
import MapKit

// MARK: - Friend Map Marker
/// Animated marker showing a friend's location with avatar and live pulse
struct FriendMapMarker: View {
    let friend: LiveFriendLocation
    let isSelected: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: 4) {
            // Main marker
            ZStack {
                // Pulse rings (only when live)
                if friend.isLive {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(NightOutColors.liveRed.opacity(0.4 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: 50 + CGFloat(index * 15), height: 50 + CGFloat(index * 15))
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                    }
                }

                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [friend.accentColor.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)

                // Avatar container
                ZStack {
                    // Border ring
                    Circle()
                        .fill(friend.isLive ? NightOutColors.liveRed : NightOutColors.partyPurple)
                        .frame(width: 48, height: 48)

                    // Avatar background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)

                    // Avatar emoji
                    Text(friend.avatarEmoji)
                        .font(.system(size: 24))
                }
                .shadow(color: friend.accentColor.opacity(0.5), radius: 8)

                // Live badge
                if friend.isLive {
                    Circle()
                        .fill(NightOutColors.liveRed)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                        .offset(x: 16, y: -16)
                }

                // Activity indicator
                if let activity = friend.currentActivity {
                    Text(activity)
                        .font(.system(size: 12))
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .offset(x: -16, y: 16)
                }
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(duration: 0.3), value: isSelected)

            // Name label (when selected)
            if isSelected {
                VStack(spacing: 2) {
                    Text(friend.displayName)
                        .font(NightOutTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(NightOutColors.chrome)

                    if let venue = friend.currentVenue {
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
        .contentShape(Rectangle())  // iOS 18+ hit-testing: must be BEFORE onTapGesture
        .onTapGesture {
            NightOutHaptics.light()
            onTap()
        }
        .onAppear {
            if friend.isLive {
                startPulseAnimation()
            }
        }
    }

    private func startPulseAnimation() {
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            pulseScale = 2.0
            pulseOpacity = 0
        }
    }
}

// MARK: - Live Friend Location Model
struct LiveFriendLocation: Identifiable {
    let id: UUID
    let userId: UUID
    let displayName: String
    let username: String
    let avatarEmoji: String
    var coordinate: CLLocationCoordinate2D
    var isLive: Bool
    var currentVenue: String?
    var currentActivity: String? // Emoji for what they're doing: 🍺 🎵 📸
    var drinkCount: Int
    var lastUpdate: Date
    var accentColor: Color

    init(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        displayName: String,
        username: String,
        avatarEmoji: String,
        latitude: Double,
        longitude: Double,
        isLive: Bool = true,
        currentVenue: String? = nil,
        currentActivity: String? = nil,
        drinkCount: Int = 0,
        lastUpdate: Date = Date(),
        accentColor: Color = NightOutColors.partyPurple
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.username = username
        self.avatarEmoji = avatarEmoji
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.isLive = isLive
        self.currentVenue = currentVenue
        self.currentActivity = currentActivity
        self.drinkCount = drinkCount
        self.lastUpdate = lastUpdate
        self.accentColor = accentColor
    }
}

// MARK: - Friend Cluster Marker
/// Shows multiple friends in one marker when zoomed out
struct FriendClusterMarker: View {
    let friends: [LiveFriendLocation]
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Stacked avatars
            ForEach(Array(friends.prefix(3).enumerated()), id: \.element.id) { index, friend in
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(friend.avatarEmoji)
                            .font(.system(size: 18))
                    }
                    .overlay {
                        Circle()
                            .stroke(friend.isLive ? NightOutColors.liveRed : NightOutColors.partyPurple, lineWidth: 2)
                    }
                    .offset(x: CGFloat(index * 12), y: CGFloat(index * -8))
            }

            // Count badge
            if friends.count > 3 {
                Text("+\(friends.count - 3)")
                    .font(NightOutTypography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(NightOutColors.partyPurple)
                    .clipShape(Capsule())
                    .offset(x: 30, y: -20)
            }
        }
        .contentShape(Rectangle())  // iOS 18+ hit-testing: must be BEFORE onTapGesture
        .onTapGesture {
            NightOutHaptics.medium()
            onTap()
        }
    }
}

// MARK: - Friend Peek Card
/// Compact info card shown when tapping a friend marker
struct FriendPeekCard: View {
    let friend: LiveFriendLocation
    let onViewProfile: () -> Void
    let onSendReaction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.md) {
            // Header
            HStack(spacing: NightOutSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(friend.accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(friend.avatarEmoji)
                        .font(.system(size: 28))

                    if friend.isLive {
                        Circle()
                            .fill(NightOutColors.liveRed)
                            .frame(width: 12, height: 12)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                            .offset(x: 18, y: -18)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(friend.displayName)
                        .font(NightOutTypography.headline)
                        .foregroundStyle(NightOutColors.chrome)

                    Text("@\(friend.username)")
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.silver)

                    if friend.isLive {
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
                }

                Spacer()
            }

            // Stats row
            HStack(spacing: NightOutSpacing.lg) {
                if let venue = friend.currentVenue {
                    StatPill(emoji: "📍", value: venue)
                }

                if friend.drinkCount > 0 {
                    StatPill(emoji: "🍺", value: "\(friend.drinkCount)")
                }

                StatPill(emoji: "⏱️", value: timeAgo(from: friend.lastUpdate))
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
        .shadow(color: friend.accentColor.opacity(0.3), radius: 20)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let emoji: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))
            Text(value)
                .font(NightOutTypography.caption2)
                .foregroundStyle(NightOutColors.silver)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(NightOutColors.surface)
        .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview("Friend Markers") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Single marker - live
            FriendMapMarker(
                friend: LiveFriendLocation(
                    displayName: "Sarah",
                    username: "sarah_party",
                    avatarEmoji: "👩‍🦰",
                    latitude: 40.7128,
                    longitude: -74.0060,
                    isLive: true,
                    currentVenue: "The Spot",
                    currentActivity: "🍺",
                    drinkCount: 3
                ),
                isSelected: true,
                onTap: {}
            )

            // Single marker - not live
            FriendMapMarker(
                friend: LiveFriendLocation(
                    displayName: "Mike",
                    username: "mike_d",
                    avatarEmoji: "🧔",
                    latitude: 40.7138,
                    longitude: -74.0070,
                    isLive: false,
                    drinkCount: 0
                ),
                isSelected: false,
                onTap: {}
            )

            // Cluster marker
            FriendClusterMarker(
                friends: [
                    LiveFriendLocation(displayName: "A", username: "a", avatarEmoji: "👩", latitude: 0, longitude: 0, isLive: true),
                    LiveFriendLocation(displayName: "B", username: "b", avatarEmoji: "👨", latitude: 0, longitude: 0, isLive: true),
                    LiveFriendLocation(displayName: "C", username: "c", avatarEmoji: "🧑", latitude: 0, longitude: 0, isLive: false),
                    LiveFriendLocation(displayName: "D", username: "d", avatarEmoji: "👱", latitude: 0, longitude: 0, isLive: true),
                    LiveFriendLocation(displayName: "E", username: "e", avatarEmoji: "👩‍🦱", latitude: 0, longitude: 0, isLive: true),
                ],
                onTap: {}
            )

            // Peek card
            FriendPeekCard(
                friend: LiveFriendLocation(
                    displayName: "Sarah",
                    username: "sarah_party",
                    avatarEmoji: "👩‍🦰",
                    latitude: 40.7128,
                    longitude: -74.0060,
                    isLive: true,
                    currentVenue: "Club Neon",
                    currentActivity: "🎵",
                    drinkCount: 4
                ),
                onViewProfile: {},
                onSendReaction: {}
            )
            .padding(.horizontal)
        }
    }
}
