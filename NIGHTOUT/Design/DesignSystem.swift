import SwiftUI
import UIKit

// MARK: - Colors
/// Dark glassmorphic color palette for NIGHTOUT party app aesthetic
enum NightOutColors {
    // Core backgrounds
    static let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let surface = Color(red: 0.12, green: 0.12, blue: 0.14)

    // Text hierarchy
    static let chrome = Color(white: 0.95)
    static let silver = Color(white: 0.78)
    static let dimmed = Color(white: 0.45)

    // Accent colors
    static let neonPink = Color(red: 1.0, green: 0.176, blue: 0.573)      // #FF2D92
    static let partyPurple = Color(red: 0.659, green: 0.333, blue: 0.969) // #A855F7
    static let electricBlue = Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6

    // Status colors
    static let liveRed = Color(red: 0.937, green: 0.267, blue: 0.267)     // #EF4444
    static let successGreen = Color(red: 0.133, green: 0.773, blue: 0.369) // #22C55E
    static let goldenHour = Color(red: 0.961, green: 0.620, blue: 0.043)  // #F59E0B

    // Glass effect colors
    static let glassBackground = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)
    static let glassHighlight = Color.white.opacity(0.25)

    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [neonPink, partyPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let liveGradient = LinearGradient(
        colors: [liveRed, neonPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceGradient = LinearGradient(
        colors: [surface.opacity(0.8), surface],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography
/// SF Pro typography system with consistent scaling
enum NightOutTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)

    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let callout = Font.system(size: 16, weight: .regular, design: .rounded)

    static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
    static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)

    // Special styles
    static let statNumber = Font.system(size: 32, weight: .bold, design: .rounded)
    static let statLabel = Font.system(size: 11, weight: .medium, design: .rounded)
    static let timer = Font.system(size: 48, weight: .bold, design: .monospaced)
    static let timerSmall = Font.system(size: 24, weight: .semibold, design: .monospaced)
}

// MARK: - Spacing
/// Consistent spacing scale (4pt base unit)
enum NightOutSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32

    // Content padding
    static let screenHorizontal: CGFloat = 16
    static let screenVertical: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let listItemPadding: CGFloat = 12
}

// MARK: - Corner Radius
/// Corner radius scale for consistent rounded corners
enum NightOutRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let pill: CGFloat = 9999

    // Specific use cases
    static let button: CGFloat = 12
    static let card: CGFloat = 16
    static let sheet: CGFloat = 24
    static let avatar: CGFloat = 9999
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

    // Prepare generators for better responsiveness
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

    static let glow = Shadow(color: NightOutColors.neonPink.opacity(0.4), radius: 12, x: 0, y: 0)
    static let liveGlow = Shadow(color: NightOutColors.liveRed.opacity(0.5), radius: 16, x: 0, y: 0)
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
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let smooth = Animation.easeInOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.5)

    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    // Pulse animation for live indicators
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
}

// MARK: - Common Emoji Constants
enum Emoji {
    static let profile = "👤"
    static let moon = "🌙"
    static let time = "⏱️"
    static let location = "📍"
    static let drink = "🍻"
    static let photo = "📸"
    static let party = "🎉"
    static let music = "🎵"
    static let heart = "❤️"
    static let fire = "🔥"
    static let star = "⭐"
    static let crown = "👑"
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

    /// Apply standard screen background
    func nightOutBackground() -> some View {
        self.background(NightOutColors.background.ignoresSafeArea())
    }

    /// Apply shadow from preset
    func shadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
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
