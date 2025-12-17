import SwiftUI

// MARK: - Shimmer Effect Modifier

/// Animated shimmer effect that sweeps across skeleton views
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if !reduceMotion {
                        shimmerGradient
                            .frame(width: geometry.size.width * 2)
                            .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    }
                }
                .clipped()
            )
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }

    private var shimmerGradient: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.15),
                Color.white.opacity(0.25),
                Color.white.opacity(0.15),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension View {
    /// Apply shimmer animation effect
    func shimmerEffect() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Base Skeleton Components

/// Animated skeleton text placeholder
@MainActor
struct SkeletonText: View {
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 120, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(NightOutColors.surface)
            .frame(width: width, height: height)
            .shimmerEffect()
    }
}

/// Animated skeleton circle placeholder (for avatars)
@MainActor
struct SkeletonCircle: View {
    let size: CGFloat

    init(size: CGFloat = 44) {
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(NightOutColors.surface)
            .frame(width: size, height: size)
            .shimmerEffect()
    }
}

/// Animated skeleton rectangle placeholder
@MainActor
struct SkeletonRect: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    init(width: CGFloat? = nil, height: CGFloat = 100, cornerRadius: CGFloat = NightOutRadius.md) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(NightOutColors.surface)
            .frame(width: width, height: height)
            .shimmerEffect()
    }
}

// MARK: - Skeleton Card

/// Skeleton card container with glass effect
@MainActor
struct SkeletonCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(NightOutSpacing.cardPadding)
            .background(NightOutColors.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
            .shimmerEffect()
    }
}

// MARK: - Feed Skeleton View

/// Skeleton loading state for HomeView feed
@MainActor
struct FeedSkeletonView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: NightOutSpacing.lg) {
                ForEach(0..<3, id: \.self) { index in
                    NightCardSkeletonView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(.horizontal, NightOutSpacing.screenHorizontal)
            .padding(.vertical, NightOutSpacing.lg)
        }
        .scrollDisabled(true)
    }
}

/// Skeleton for individual night card
@MainActor
struct NightCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: NightOutSpacing.md) {
                SkeletonCircle(size: 44)

                VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                    SkeletonText(width: 120, height: 16)
                    SkeletonText(width: 80, height: 12)
                }

                Spacer()

                SkeletonText(width: 60, height: 12)
            }
            .padding(NightOutSpacing.cardPadding)

            // Image placeholder
            SkeletonRect(height: 200, cornerRadius: 0)

            // Footer
            HStack(spacing: NightOutSpacing.lg) {
                // Stats
                HStack(spacing: NightOutSpacing.sm) {
                    SkeletonText(width: 40, height: 14)
                    SkeletonText(width: 40, height: 14)
                    SkeletonText(width: 40, height: 14)
                }

                Spacer()

                // Like button
                SkeletonCircle(size: 24)
            }
            .padding(NightOutSpacing.cardPadding)
        }
        .background(NightOutColors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Profile Skeleton View

/// Skeleton loading state for ProfileView
@MainActor
struct ProfileSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: NightOutSpacing.xxl) {
                // Avatar and name
                VStack(spacing: NightOutSpacing.md) {
                    SkeletonCircle(size: 100)
                    SkeletonText(width: 140, height: 24)
                    SkeletonText(width: 100, height: 14)
                }
                .padding(.top, NightOutSpacing.xl)

                // Stats row
                HStack(spacing: NightOutSpacing.xxl) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: NightOutSpacing.xs) {
                            SkeletonText(width: 40, height: 28)
                            SkeletonText(width: 60, height: 12)
                        }
                    }
                }

                // Recent nights
                VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                    SkeletonText(width: 100, height: 18)

                    ForEach(0..<2, id: \.self) { _ in
                        NightCardSkeletonView()
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
        .scrollDisabled(true)
    }
}

// MARK: - Stats Skeleton View

/// Skeleton loading state for StatsView
@MainActor
struct StatsSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: NightOutSpacing.xxl) {
                // Period selector
                HStack(spacing: NightOutSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonText(width: 70, height: 32)
                    }
                }
                .padding(.top, NightOutSpacing.lg)

                // Main stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NightOutSpacing.lg) {
                    ForEach(0..<4, id: \.self) { _ in
                        StatCardSkeletonView()
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)

                // Chart placeholder
                VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                    SkeletonText(width: 120, height: 18)
                    SkeletonRect(height: 200, cornerRadius: NightOutRadius.md)
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
        .scrollDisabled(true)
    }
}

@MainActor
struct StatCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
            SkeletonCircle(size: 32)
            SkeletonText(width: 60, height: 28)
            SkeletonText(width: 80, height: 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NightOutSpacing.cardPadding)
        .background(NightOutColors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Map Skeleton View

/// Skeleton loading state for LiveView map
@MainActor
struct MapSkeletonView: View {
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Map placeholder
            Rectangle()
                .fill(NightOutColors.surface.opacity(0.3))
                .shimmerEffect()

            // Center loading indicator
            VStack(spacing: NightOutSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(NightOutColors.neonPink.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)

                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundStyle(NightOutColors.silver)
                }

                SkeletonText(width: 140, height: 16)
            }
        }
        .onAppear {
            withAnimation(NightOutAnimation.pulse) {
                pulseScale = 1.2
            }
        }
    }
}

// MARK: - Tracking Skeleton View

/// Skeleton loading state for ActiveTrackingView
@MainActor
struct TrackingSkeletonView: View {
    var body: some View {
        VStack(spacing: NightOutSpacing.xxxl) {
            Spacer()

            // Timer placeholder
            VStack(spacing: NightOutSpacing.md) {
                SkeletonText(width: 180, height: 48)
                SkeletonText(width: 100, height: 14)
            }

            // Stats row
            HStack(spacing: NightOutSpacing.xxl) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: NightOutSpacing.xs) {
                        SkeletonText(width: 50, height: 24)
                        SkeletonText(width: 60, height: 12)
                    }
                }
            }

            Spacer()

            // Quick actions
            HStack(spacing: NightOutSpacing.lg) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonCircle(size: 60)
                }
            }

            // End button
            SkeletonRect(width: 200, height: 50, cornerRadius: NightOutRadius.pill)
                .padding(.bottom, NightOutSpacing.xxxl)
        }
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
    }
}

// MARK: - Detail Skeleton View

/// Skeleton loading state for NightDetailView
@MainActor
struct DetailSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NightOutSpacing.xxl) {
                // Header image
                SkeletonRect(height: 250, cornerRadius: 0)

                VStack(alignment: .leading, spacing: NightOutSpacing.lg) {
                    // Title and meta
                    VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
                        SkeletonText(width: 200, height: 28)
                        SkeletonText(width: 150, height: 16)
                    }

                    // Stats row
                    HStack(spacing: NightOutSpacing.xl) {
                        ForEach(0..<4, id: \.self) { _ in
                            VStack(spacing: NightOutSpacing.xs) {
                                SkeletonText(width: 40, height: 20)
                                SkeletonText(width: 50, height: 12)
                            }
                        }
                    }

                    // Caption
                    VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                        SkeletonText(width: .infinity, height: 14)
                        SkeletonText(width: 250, height: 14)
                    }

                    // Timeline section
                    VStack(alignment: .leading, spacing: NightOutSpacing.md) {
                        SkeletonText(width: 100, height: 18)

                        ForEach(0..<3, id: \.self) { _ in
                            TimelineItemSkeletonView()
                        }
                    }
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
        .scrollDisabled(true)
    }
}

@MainActor
struct TimelineItemSkeletonView: View {
    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            SkeletonCircle(size: 8)

            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                SkeletonText(width: 140, height: 14)
                SkeletonText(width: 80, height: 12)
            }

            Spacer()

            SkeletonText(width: 50, height: 12)
        }
    }
}

// MARK: - Comment Skeleton View

/// Skeleton for comment list items
@MainActor
struct CommentSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: NightOutSpacing.md) {
            SkeletonCircle(size: 36)

            VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                HStack(spacing: NightOutSpacing.sm) {
                    SkeletonText(width: 80, height: 14)
                    SkeletonText(width: 40, height: 12)
                }
                SkeletonText(width: 200, height: 14)
            }
        }
    }
}

// MARK: - Friends List Skeleton

@MainActor
struct FriendsListSkeletonView: View {
    var body: some View {
        VStack(spacing: NightOutSpacing.md) {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: NightOutSpacing.md) {
                    SkeletonCircle(size: 50)

                    VStack(alignment: .leading, spacing: NightOutSpacing.xs) {
                        SkeletonText(width: 120, height: 16)
                        SkeletonText(width: 80, height: 12)
                    }

                    Spacer()

                    SkeletonRect(width: 70, height: 32, cornerRadius: NightOutRadius.button)
                }
                .padding(.horizontal, NightOutSpacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Preview

#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: NightOutSpacing.xxl) {
            Group {
                Text("Text Skeletons")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
                    SkeletonText(width: 200, height: 20)
                    SkeletonText(width: 150, height: 14)
                    SkeletonText(width: 100, height: 12)
                }
            }

            Group {
                Text("Circle Skeletons")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                HStack(spacing: NightOutSpacing.lg) {
                    SkeletonCircle(size: 32)
                    SkeletonCircle(size: 44)
                    SkeletonCircle(size: 60)
                }
            }

            Group {
                Text("Night Card Skeleton")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(NightOutColors.chrome)

                NightCardSkeletonView()
            }
        }
        .padding()
    }
    .nightOutBackground()
}

#Preview("Feed Skeleton") {
    FeedSkeletonView()
        .nightOutBackground()
}

#Preview("Profile Skeleton") {
    ProfileSkeletonView()
        .nightOutBackground()
}

#Preview("Stats Skeleton") {
    StatsSkeletonView()
        .nightOutBackground()
}
