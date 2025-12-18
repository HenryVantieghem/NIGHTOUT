import SwiftUI

// MARK: - Disco Ball Logo
/// Animated disco ball logo with purple glow ring
@MainActor
struct DiscoBallLogo: View {
    let size: CGFloat
    @State private var rotation: Double = 0

    init(size: CGFloat = 80) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // Purple glow background
            Circle()
                .fill(NightOutColors.purpleGlow)
                .frame(width: size + 40, height: size + 40)

            // Purple ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            NightOutColors.partyPurple.opacity(0.8),
                            NightOutColors.partyPurple.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .frame(width: size + 10, height: size + 10)
                .shadow(color: NightOutColors.partyPurple.opacity(0.5), radius: 20)

            // Disco ball emoji
            Text(Emoji.discoBall)
                .font(.system(size: size * 0.75))
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Sign In/Up Toggle
/// Pill-shaped toggle for switching between sign in and sign up
@MainActor
struct AuthToggle: View {
    @Binding var isSignUp: Bool

    var body: some View {
        HStack(spacing: 0) {
            AuthToggleButton(title: "Sign In", isSelected: !isSignUp) {
                withAnimation(NightOutAnimation.snappy) {
                    isSignUp = false
                }
            }

            AuthToggleButton(title: "Sign Up", isSelected: isSignUp) {
                withAnimation(NightOutAnimation.snappy) {
                    isSignUp = true
                }
            }
        }
        .padding(4)
        .background(NightOutColors.surface)
        .clipShape(Capsule())
    }
}

@MainActor
private struct AuthToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            NightOutHaptics.selection()
            action()
        }) {
            Text(title)
                .font(NightOutTypography.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? NightOutColors.chrome : NightOutColors.silver)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? NightOutColors.surfaceMedium : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Ultra Glass Input Field
/// Pixel-perfect input field matching screenshots
@MainActor
struct UltraInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        HStack(spacing: NightOutSpacing.md) {
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.chrome)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .font(NightOutTypography.body)
                    .foregroundStyle(NightOutColors.chrome)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
            }
        }
        .padding(.horizontal, NightOutSpacing.lg)
        .frame(height: 56)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.input))
        .overlay(
            RoundedRectangle(cornerRadius: NightOutRadius.input)
                .stroke(NightOutColors.glassBorder, lineWidth: 1)
        )
    }
}

// MARK: - Primary Gradient Button
/// Large CTA button with gradient background
@MainActor
struct PrimaryGradientButton: View {
    let title: String
    var emoji: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.medium()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(NightOutTypography.headline)

                    if let emoji {
                        Text(emoji)
                            .font(.system(size: 20))
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(NightOutColors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.button))
            .shadow(color: NightOutColors.partyPurple.opacity(0.4), radius: 16, y: 4)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1)
    }
}

// MARK: - Add Drink FAB
/// Floating action button for adding drinks
@MainActor
struct AddDrinkFAB: View {
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.medium()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.sm) {
                Text(Emoji.drinks)
                    .font(.system(size: 24))

                Text("Add Drink")
                    .font(NightOutTypography.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(NightOutColors.addDrinkGradient)
            .clipShape(Capsule())
            .shadow(color: NightOutColors.neonPink.opacity(0.5), radius: 20, y: 8)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }
}

// MARK: - Moon End Button
/// Circular button for ending the night
@MainActor
struct MoonEndButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.medium()
            action()
        } label: {
            Text(Emoji.moon)
                .font(.system(size: 24))
                .frame(width: 56, height: 56)
                .background(NightOutColors.surface)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(NightOutColors.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

// MARK: - Stat Card
/// Individual stat display card with emoji
@MainActor
struct StatCard: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: NightOutSpacing.sm) {
            Text(emoji)
                .font(.system(size: 28))

            Text(value)
                .font(NightOutTypography.statNumber)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.statLabel)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NightOutSpacing.lg)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Night Grid Card
/// Card for displaying a night in the profile grid
@MainActor
struct NightGridCard: View {
    let duration: String
    let title: String
    let date: String

    var body: some View {
        VStack(spacing: NightOutSpacing.sm) {
            Spacer()

            Text(Emoji.discoBall)
                .font(.system(size: 32))

            Text(duration)
                .font(NightOutTypography.subheadline)
                .foregroundStyle(NightOutColors.chrome)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "Untitled" : title)
                    .font(NightOutTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(NightOutColors.chrome)
                    .lineLimit(1)

                Text(date)
                    .font(NightOutTypography.caption2)
                    .foregroundStyle(NightOutColors.silver)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NightOutSpacing.lg)
        .aspectRatio(1, contentMode: .fit)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Profile Stats Row
/// Horizontal row of profile stats
@MainActor
struct ProfileStatsRow: View {
    let nights: Int
    let friends: Int
    let posts: Int

    var body: some View {
        HStack(spacing: 0) {
            ProfileStatColumn(value: nights, label: "Nights")
            ProfileStatColumn(value: friends, label: "Friends")
            ProfileStatColumn(value: posts, label: "Posts")
        }
    }
}

@MainActor
private struct ProfileStatColumn: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: NightOutSpacing.xs) {
            Text("\(value)")
                .font(NightOutTypography.title2)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.statLabel)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Edit Profile Button
/// Pill button for editing profile
@MainActor
struct EditProfileButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.light()
            action()
        } label: {
            HStack(spacing: NightOutSpacing.sm) {
                Text("✏️")
                    .font(.system(size: 16))

                Text("Edit Profile")
                    .font(NightOutTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(NightOutColors.chrome)
            }
            .padding(.horizontal, NightOutSpacing.lg)
            .frame(height: 40)
            .background(NightOutColors.surfaceMedium)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }
}

// MARK: - Section Header
/// Standard section header with optional "See All" link
@MainActor
struct UltraSectionHeader: View {
    let title: String
    var rightText: String? = nil
    var rightAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(NightOutTypography.caption)
                .foregroundStyle(NightOutColors.silver)
                .textCase(.uppercase)
                .tracking(1)

            Spacer()

            if let rightText, let rightAction {
                Button {
                    NightOutHaptics.light()
                    rightAction()
                } label: {
                    Text(rightText)
                        .font(NightOutTypography.caption)
                        .foregroundStyle(NightOutColors.partyPurple)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else if let rightText {
                Text(rightText)
                    .font(NightOutTypography.caption)
                    .foregroundStyle(NightOutColors.chrome)
            }
        }
        .padding(.horizontal, NightOutSpacing.screenHorizontal)
    }
}

// MARK: - Timer Card
/// Glass card displaying the active night timer
@MainActor
struct TimerCard: View {
    let time: String
    let vibeName: String?
    let friendCount: Int
    @Binding var isPulsing: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: NightOutSpacing.sm) {
                Text(time)
                    .font(NightOutTypography.timerDisplay)
                    .foregroundStyle(NightOutColors.chrome)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if let vibeName, !vibeName.isEmpty {
                    Text("\"\(vibeName)\"")
                        .font(NightOutTypography.subheadline)
                        .foregroundStyle(NightOutColors.silver)
                }
            }

            Spacer()

            // Friends indicator
            HStack(spacing: NightOutSpacing.xs) {
                Circle()
                    .fill(NightOutColors.liveRed)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(NightOutColors.electricBlue)
            }
        }
        .padding(NightOutSpacing.xl)
        .background(NightOutColors.glassBackground)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NightOutRadius.card)
                .stroke(NightOutColors.glassHighlight, lineWidth: 1)
        )
    }
}

// MARK: - Stat Pill
/// Horizontal stat pill for tracking view
@MainActor
struct StatPill: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: NightOutSpacing.xs) {
            Text(emoji)
                .font(.system(size: 16))

            Text(value)
                .font(NightOutTypography.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(NightOutColors.chrome)

            Text(label)
                .font(NightOutTypography.caption2)
                .foregroundStyle(NightOutColors.silver)
        }
        .padding(.horizontal, NightOutSpacing.md)
        .padding(.vertical, NightOutSpacing.sm)
        .background(NightOutColors.glassBackground)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Quick Action Button
/// Square action button for tracking view
@MainActor
struct QuickActionItem: View {
    let emoji: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.light()
            action()
        } label: {
            VStack(spacing: NightOutSpacing.xs) {
                Text(emoji)
                    .font(.system(size: 24))

                Text(label)
                    .font(NightOutTypography.caption2)
                    .foregroundStyle(NightOutColors.silver)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, NightOutSpacing.md)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MARK: - Recording Indicator
/// Red pulsing recording indicator
@MainActor
struct RecordingIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: NightOutSpacing.xs) {
            Circle()
                .fill(NightOutColors.liveRed)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .shadow(color: NightOutColors.liveRed.opacity(isPulsing ? 0.6 : 0.3), radius: isPulsing ? 8 : 4)

            Text("I")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(NightOutColors.liveRed)
        }
        .padding(.horizontal, NightOutSpacing.sm)
        .padding(.vertical, NightOutSpacing.xs)
        .background(NightOutColors.liveRed.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(NightOutColors.liveRed.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(NightOutAnimation.pulse) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Avatar with Camera Badge
/// Profile avatar with camera edit badge
@MainActor
struct AvatarWithBadge: View {
    let url: URL?
    let name: String
    let size: CGFloat
    var showCameraBadge: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            Group {
                if let url {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        defaultAvatar
                    }
                } else {
                    defaultAvatar
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            // Camera badge
            if showCameraBadge {
                Image(systemName: "camera.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(NightOutColors.partyPurple)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }
        }
    }

    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(NightOutColors.surfaceMedium)

            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(NightOutColors.electricBlue.opacity(0.6))
        }
    }
}

// MARK: - Activity Chart Placeholder
/// Placeholder card for activity chart
@MainActor
struct ActivityChartCard: View {
    var body: some View {
        VStack(spacing: NightOutSpacing.md) {
            Text("📊")
                .font(.system(size: 32))

            Text("Activity Chart")
                .font(NightOutTypography.subheadline)
                .foregroundStyle(NightOutColors.silver)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(NightOutColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }
}

// MARK: - Custom Tab Bar (Ultra Version)
/// Pixel-perfect tab bar matching screenshots
@MainActor
struct UltraTabBar: View {
    @Binding var selectedTab: Int
    let hasActiveNight: Bool
    let onTrackTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Feed
            UltraTabItem(
                icon: "house.fill",
                label: "Feed",
                isSelected: selectedTab == 0,
                tint: NightOutColors.neonPink
            ) {
                selectedTab = 0
            }

            // Live
            UltraTabItem(
                icon: "circle.fill",
                label: "Live",
                isSelected: selectedTab == 1,
                tint: NightOutColors.liveRed,
                showDot: true
            ) {
                selectedTab = 1
            }

            // Center Track Button
            UltraCenterButton(
                hasActiveNight: hasActiveNight,
                action: onTrackTapped
            )

            // Stats
            UltraTabItem(
                icon: "chart.bar.fill",
                label: "Stats",
                isSelected: selectedTab == 3,
                tint: NightOutColors.neonPink
            ) {
                selectedTab = 3
            }

            // Profile
            UltraTabItem(
                icon: "person.fill",
                label: "Profile",
                isSelected: selectedTab == 4,
                tint: NightOutColors.neonPink
            ) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, NightOutSpacing.md)
        .padding(.top, NightOutSpacing.md)
        .padding(.bottom, NightOutSpacing.tabBarSafeArea)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(NightOutColors.background.opacity(0.5))
                )
                .overlay(
                    LinearGradient(
                        colors: [NightOutColors.glassBorder, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea()
        )
    }
}

@MainActor
private struct UltraTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let tint: Color
    var showDot: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            NightOutHaptics.selection()
            action()
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? tint : NightOutColors.silver)

                    if showDot {
                        Circle()
                            .fill(NightOutColors.liveRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -2)
                    }
                }

                Text(label)
                    .font(NightOutTypography.tabLabel)
                    .foregroundStyle(isSelected ? tint : NightOutColors.dimmed)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

@MainActor
private struct UltraCenterButton: View {
    let hasActiveNight: Bool
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button {
            NightOutHaptics.medium()
            action()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Glow effect when active
                    if hasActiveNight {
                        Circle()
                            .fill(NightOutColors.liveRed.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .opacity(isPulsing ? 0.5 : 0.8)
                    }

                    // Main button
                    Circle()
                        .stroke(
                            hasActiveNight
                                ? NightOutColors.liveRed
                                : NightOutColors.partyPurple,
                            lineWidth: 2
                        )
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: (hasActiveNight ? NightOutColors.liveRed : NightOutColors.partyPurple).opacity(0.3),
                            radius: 12
                        )

                    // Icon
                    Text(Emoji.discoBall)
                        .font(.system(size: 32))
                }
                .offset(y: -12)

                Text(hasActiveNight ? "LIVE" : "Track")
                    .font(NightOutTypography.tabLabel)
                    .foregroundStyle(hasActiveNight ? NightOutColors.liveRed : NightOutColors.silver)
                    .offset(y: -8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onAppear {
            if hasActiveNight {
                withAnimation(NightOutAnimation.pulse) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: hasActiveNight) { _, active in
            if active {
                withAnimation(NightOutAnimation.pulse) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Glass Text Field Style
/// Standard glass text field style
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(NightOutTypography.body)
            .foregroundStyle(NightOutColors.chrome)
            .padding(.horizontal, NightOutSpacing.lg)
            .frame(height: 56)
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.input))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.input)
                    .stroke(NightOutColors.glassBorder, lineWidth: 1)
            )
    }
}

// MARK: - Preview Helpers
#Preview("Disco Ball Logo") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()
        DiscoBallLogo(size: 80)
    }
}

#Preview("Auth Toggle") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()
        AuthToggle(isSignUp: .constant(true))
            .padding()
    }
}

#Preview("Stat Card") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(emoji: "🌙", value: "13", label: "Nights")
            StatCard(emoji: "⏱️", value: "1h", label: "Total")
            StatCard(emoji: "🏃", value: "0.4 mi", label: "Distance")
            StatCard(emoji: "🍺", value: "12", label: "Drinks")
        }
        .padding()
    }
}

#Preview("Night Grid Card") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NightGridCard(duration: "00:05", title: "Untitled", date: "Tuesday, December 16")
            NightGridCard(duration: "00:03", title: "Untitled", date: "Tuesday, December 16")
        }
        .padding()
    }
}

#Preview("Tab Bar") {
    ZStack {
        NightOutColors.background.ignoresSafeArea()
        VStack {
            Spacer()
            UltraTabBar(
                selectedTab: .constant(0),
                hasActiveNight: false,
                onTrackTapped: {}
            )
        }
    }
}
