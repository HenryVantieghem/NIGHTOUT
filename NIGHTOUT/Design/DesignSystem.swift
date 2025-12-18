import SwiftUI
import UIKit

// MARK: - Colors
/// Dark glassmorphic color palette for NIGHTOUT party app aesthetic
/// Extracted pixel-perfect from reference screenshots
enum NightOutColors {
    // Core backgrounds
    static let background = Color(red: 0.0, green: 0.0, blue: 0.0)              // #000000 - Pure black
    static let voidBlack = Color(red: 0.039, green: 0.039, blue: 0.047)         // #0A0A0C
    static let surface = Color(red: 0.102, green: 0.102, blue: 0.118)           // #1A1A1E - Cards
    static let surfaceMedium = Color(red: 0.165, green: 0.165, blue: 0.188)     // #2A2A30 - Elevated
    static let surfaceLight = Color(red: 0.251, green: 0.251, blue: 0.282)      // #404048 - Borders

    // Text hierarchy
    static let chrome = Color.white                                              // #FFFFFF - Primary
    static let silver = Color(red: 0.627, green: 0.627, blue: 0.659)            // #A0A0A8 - Secondary
    static let dimmed = Color(red: 0.376, green: 0.376, blue: 0.408)            // #606068 - Placeholder
    static let muted = Color(red: 0.251, green: 0.251, blue: 0.282)             // #404048 - Very subtle

    // Accent colors
    static let partyPurple = Color(red: 0.545, green: 0.361, blue: 0.965)       // #8B5CF6 - Primary accent
    static let neonPink = Color(red: 1.0, green: 0.176, blue: 0.573)            // #FF2D92 - Highlights
    static let lightPink = Color(red: 1.0, green: 0.420, blue: 0.616)           // #FF6B9D - Button gradient start
    static let magenta = Color(red: 0.784, green: 0.314, blue: 0.753)           // #C850C0 - Button gradient end
    static let electricBlue = Color(red: 0.231, green: 0.510, blue: 0.965)      // #3B82F6 - Info

    // Status colors
    static let liveRed = Color(red: 0.937, green: 0.267, blue: 0.267)           // #EF4444 - Recording/Live
    static let successGreen = Color(red: 0.133, green: 0.773, blue: 0.369)      // #22C55E - Success
    static let goldenHour = Color(red: 0.961, green: 0.620, blue: 0.043)        // #F59E0B - Achievements
    static let yellowAccent = Color(red: 0.980, green: 0.800, blue: 0.082)      // #FACC15 - Stars

    // Glass effect colors
    static let glassBackground = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.10)
    static let glassHighlight = Color.white.opacity(0.15)
    static let glassStrong = Color.white.opacity(0.20)

    // MARK: - Gradients

    /// Primary CTA button gradient (pink to purple)
    static let primaryGradient = LinearGradient(
        colors: [lightPink, partyPurple],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Add drink button gradient (light pink to magenta)
    static let addDrinkGradient = LinearGradient(
        colors: [lightPink, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Live/recording gradient
    static let liveGradient = LinearGradient(
        colors: [liveRed, neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Surface gradient for subtle depth
    static let surfaceGradient = LinearGradient(
        colors: [surface.opacity(0.8), surface],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Background vignette gradient
    static let backgroundVignette = RadialGradient(
        colors: [
            Color(red: 0.102, green: 0.039, blue: 0.125), // Dark purple tint
            background
        ],
        center: .top,
        startRadius: 0,
        endRadius: 600
    )

    /// Purple glow for disco ball
    static let purpleGlow = RadialGradient(
        colors: [
            partyPurple.opacity(0.6),
            partyPurple.opacity(0.0)
        ],
        center: .center,
        startRadius: 40,
        endRadius: 70
    )
}

// MARK: - Typography
/// SF Pro Rounded typography system - pixel-perfect from screenshots
enum NightOutTypography {
    // Display
    static let timerDisplay = Font.system(size: 56, weight: .bold, design: .rounded)

    // Titles
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Body
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)

    // Small
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    // Special styles
    static let statNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    static let statLabel = Font.system(size: 11, weight: .medium, design: .rounded)
    static let timer = Font.system(size: 48, weight: .bold, design: .monospaced)
    static let timerSmall = Font.system(size: 24, weight: .semibold, design: .monospaced)

    // Tab bar
    static let tabLabel = Font.system(size: 10, weight: .medium, design: .rounded)
}

// MARK: - Spacing
/// Consistent spacing scale (4pt base unit) - pixel-perfect
enum NightOutSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48

    // Content padding
    static let screenHorizontal: CGFloat = 16
    static let screenVertical: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let listItemPadding: CGFloat = 12

    // Safe areas
    static let tabBarHeight: CGFloat = 49
    static let tabBarSafeArea: CGFloat = 34
    static let tabBarTotal: CGFloat = 83
}

// MARK: - Corner Radius
/// Corner radius scale - pixel-perfect from screenshots
enum NightOutRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 9999

    // Specific use cases
    static let button: CGFloat = 16
    static let input: CGFloat = 12
    static let card: CGFloat = 16
    static let sheet: CGFloat = 24
    static let avatar: CGFloat = 9999
    static let statPill: CGFloat = 20
    static let fabButton: CGFloat = 28
}

// MARK: - Haptics
/// Haptic feedback utilities for tactile responses
enum NightOutHaptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func light() {
        lightGenerator.impactOccurred()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
    }

    static func heavy() {
        heavyGenerator.impactOccurred()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    static func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    static func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    static func selection() {
        selectionGenerator.selectionChanged()
    }

    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}

// MARK: - Shadows
/// Shadow styles for depth and elevation
enum NightOutShadows {
    static let small = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

    // Glow effects
    static let purpleGlow = Shadow(color: NightOutColors.partyPurple.opacity(0.4), radius: 16, x: 0, y: 4)
    static let pinkGlow = Shadow(color: NightOutColors.neonPink.opacity(0.5), radius: 20, x: 0, y: 8)
    static let liveGlow = Shadow(color: NightOutColors.liveRed.opacity(0.6), radius: 12, x: 0, y: 0)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Animation
/// Animation presets for consistent motion
enum NightOutAnimation {
    // Basic timing
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let smooth = Animation.easeInOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.5)

    // Spring animations
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.7)
    static let rubberBand = Animation.spring(response: 0.3, dampingFraction: 0.5)
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)

    // Pulse animation for live indicators
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)

    // Float animation for empty states
    static let float = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)

    // Stagger helper for list animations
    static func stagger(index: Int, baseDelay: Double = 0.05) -> Animation {
        .easeOut(duration: 0.3).delay(Double(index) * baseDelay)
    }
}

// MARK: - Common Emoji Constants
enum Emoji {
    // Logo & Branding
    static let discoBall = "🪩"
    static let moon = "🌙"
    static let party = "🎉"

    // Stats
    static let nights = "🌙"
    static let time = "⏱️"
    static let distance = "🏃"
    static let drinks = "🍺"
    static let songs = "🎵"
    static let photos = "📸"
    static let spots = "📍"

    // Actions
    static let camera = "📸"
    static let sparkles = "✨"

    // Social
    static let profile = "👤"
    static let friends = "👥"
    static let heart = "❤️"
    static let fire = "🔥"
    static let star = "⭐"
    static let crown = "👑"

    // Input fields
    static let email = "📧"
    static let password = "🔒"
}

// MARK: - Club Atmosphere
/// Ambient effect for live views
@MainActor
struct ClubAtmosphere: View {
    enum Intensity: Double {
        case chill = 0.3
        case moderate = 0.5
        case intense = 0.7
        case wild = 0.9
    }

    let intensity: Intensity

    init(intensity: Intensity = .moderate) {
        self.intensity = intensity
    }

    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        NightOutColors.partyPurple.opacity(intensity.rawValue * 0.3),
                        NightOutColors.neonPink.opacity(intensity.rawValue * 0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 400
                )
            )
            .ignoresSafeArea()
    }
}

// MARK: - View Extensions
extension View {
    /// Apply pulsing animation effect
    func beatPulse(intensity: Double = 0.5, bpm: Double = 120) -> some View {
        self.modifier(BeatPulseModifier(intensity: intensity, bpm: bpm))
    }

    /// Apply standard card styling with glass effect
    func glassCard() -> some View {
        self
            .background(NightOutColors.glassBackground)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NightOutRadius.card)
                    .stroke(NightOutColors.glassBorder, lineWidth: 1)
            )
    }

    /// Apply solid dark card styling (no glass blur)
    func solidCard() -> some View {
        self
            .background(NightOutColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: NightOutRadius.card))
    }

    /// Apply standard screen background
    func nightOutBackground() -> some View {
        self.background(NightOutColors.background.ignoresSafeArea())
    }

    /// Apply vignette background
    func vignetteBackground() -> some View {
        self.background(NightOutColors.backgroundVignette.ignoresSafeArea())
    }

    /// Apply shadow from preset
    func shadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Apply press animation (scale down on press)
    func pressAnimation(scale: CGFloat = 0.95) -> some View {
        self.modifier(PressAnimationModifier(scale: scale))
    }

    /// Apply appear animation (fade + slide up)
    func appearAnimation(delay: Double = 0) -> some View {
        self.modifier(AppearAnimationModifier(delay: delay))
    }

    /// Apply floating animation for empty states
    func floatingAnimation(offset: CGFloat = 8) -> some View {
        self.modifier(FloatingAnimationModifier(offset: offset))
    }

    /// Apply stagger animation for list items
    func staggerAnimation(index: Int, baseDelay: Double = 0.05) -> some View {
        self.modifier(StaggerAnimationModifier(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Beat Pulse Modifier
struct BeatPulseModifier: ViewModifier {
    let intensity: Double
    let bpm: Double
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.0 + intensity * 0.2 : 1.0)
            .opacity(isPulsing ? 1.0 : 1.0 - intensity * 0.3)
            .onAppear {
                let duration = 60.0 / bpm / 2.0
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Press Animation Modifier
struct PressAnimationModifier: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? scale : 1.0)
            .animation(NightOutAnimation.snappy, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Appear Animation Modifier
struct AppearAnimationModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 20)
            .onAppear {
                guard !reduceMotion else {
                    hasAppeared = true
                    return
                }
                withAnimation(NightOutAnimation.smoothSpring.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Floating Animation Modifier
struct FloatingAnimationModifier: ViewModifier {
    let offset: CGFloat
    @State private var isFloating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating && !reduceMotion ? -offset : offset)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(NightOutAnimation.float) {
                    isFloating = true
                }
            }
    }
}

// MARK: - Stagger Animation Modifier
struct StaggerAnimationModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 15)
            .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.95)
            .onAppear {
                guard !reduceMotion else {
                    hasAppeared = true
                    return
                }
                withAnimation(NightOutAnimation.stagger(index: index, baseDelay: baseDelay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Animated Counter
/// Animates number changes with spring animation
@MainActor
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    init(value: Int, font: Font = NightOutTypography.statNumber, color: Color = NightOutColors.chrome) {
        self.value = value
        self.font = font
        self.color = color
    }

    var body: some View {
        Text("\(value)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: Double(value)))
            .animation(NightOutAnimation.smoothSpring, value: value)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
