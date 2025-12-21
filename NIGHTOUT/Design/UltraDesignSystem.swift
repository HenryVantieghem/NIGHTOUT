import SwiftUI
import UIKit

// MARK: - Ultra Premium Design System
// "Holographic Nightclub" - Tokyo club meets Miami Vice meets Instagram Stories
// Bold maximalism with holographic effects, liquid gradients, and cinematic depth

// MARK: - Device Responsive Sizing
enum DeviceSize {
    case small      // iPhone SE, Mini
    case medium     // iPhone 14, 15
    case large      // iPhone Pro Max
    case tablet     // iPad

    static var current: DeviceSize {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let maxDimension = max(width, height)

        if UIDevice.current.userInterfaceIdiom == .pad {
            return .tablet
        } else if maxDimension <= 667 { // SE, 8
            return .small
        } else if maxDimension <= 844 { // Standard iPhones
            return .medium
        } else {
            return .large
        }
    }

    // Scaling factor for responsive sizing
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.1
        case .tablet: return 1.25
        }
    }
}

// MARK: - Ultra Colors (Holographic Nightclub Palette)
enum UltraColors {
    // Deep space backgrounds
    static let void = Color(red: 0.02, green: 0.02, blue: 0.04)
    static let abyss = Color(red: 0.04, green: 0.04, blue: 0.08)
    static let midnight = Color(red: 0.06, green: 0.05, blue: 0.12)
    static let background = Color(red: 0.03, green: 0.03, blue: 0.05)
    static let surface = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let cardBackground = Color(red: 0.10, green: 0.10, blue: 0.15)

    // Holographic neons (ultra saturated)
    static let plasmaPin = Color(red: 1.0, green: 0.08, blue: 0.58)      // #FF14FF - Electric Magenta
    static let cyberViolet = Color(red: 0.72, green: 0.18, blue: 1.0)    // #B72EFF - Cyber Purple
    static let laserBlue = Color(red: 0.0, green: 0.75, blue: 1.0)       // #00BFFF - Laser Blue
    static let neonMint = Color(red: 0.0, green: 1.0, blue: 0.78)        // #00FFC8 - Mint Glow
    static let sunburstGold = Color(red: 1.0, green: 0.82, blue: 0.0)    // #FFD100 - Gold
    static let solarGold = Color(red: 1.0, green: 0.82, blue: 0.0)      // Alias for sunburstGold
    static let fireOrange = Color(red: 1.0, green: 0.42, blue: 0.18)     // #FF6B2E - Fire
    static let electricCyan = Color(red: 0.0, green: 0.9, blue: 0.9)     // Cyan accent

    // Status
    static let liveRed = Color(red: 1.0, green: 0.22, blue: 0.22)        // #FF3838
    static let successMint = Color(red: 0.12, green: 0.95, blue: 0.68)   // #1FF2AD
    static let successGreen = Color(red: 0.0, green: 0.9, blue: 0.5)    // Success green

    // Text hierarchy
    static let titanium = Color(red: 0.96, green: 0.96, blue: 0.98)      // Pure white
    static let chrome = Color(white: 0.98)                              // Chrome text
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.80)
    static let slate = Color(red: 0.45, green: 0.45, blue: 0.52)
    static let dimmed = Color(white: 0.50)                                // Dimmed text

    // Glass effects
    static let glassWhite = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)
    static let glassHighlight = Color.white.opacity(0.5)

    // MARK: - Premium Gradients

    /// Primary CTA gradient - hot to electric
    static let primaryGradient = LinearGradient(
        stops: [
            .init(color: plasmaPin, location: 0),
            .init(color: cyberViolet, location: 0.5),
            .init(color: laserBlue, location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Holographic rainbow for borders
    static let holographicGradient = AngularGradient(
        colors: [
            plasmaPin,
            fireOrange,
            sunburstGold,
            neonMint,
            laserBlue,
            cyberViolet,
            plasmaPin
        ],
        center: .center
    )

    /// Liquid metal gradient
    static let liquidMetal = LinearGradient(
        stops: [
            .init(color: Color(white: 0.9), location: 0),
            .init(color: Color(white: 0.6), location: 0.3),
            .init(color: Color(white: 0.8), location: 0.5),
            .init(color: Color(white: 0.5), location: 0.7),
            .init(color: Color(white: 0.7), location: 1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sunset gradient for warm accents
    static let sunsetGradient = LinearGradient(
        colors: [fireOrange, plasmaPin, cyberViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Cool ocean gradient
    static let oceanGradient = LinearGradient(
        colors: [neonMint, laserBlue, cyberViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// VIP gold gradient
    static let vipGold = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.92, blue: 0.6),
            sunburstGold,
            Color(red: 0.85, green: 0.65, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Aurora borealis background (iOS 17 compatible fallback)
    static let auroraGradient = LinearGradient(
        colors: [
            void,
            cyberViolet.opacity(0.3),
            plasmaPin.opacity(0.2),
            laserBlue.opacity(0.3),
            midnight
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Live pulse glow
    static let liveGlow = RadialGradient(
        colors: [liveRed.opacity(0.6), liveRed.opacity(0.2), .clear],
        center: .center,
        startRadius: 5,
        endRadius: 50
    )
}

// MARK: - Ultra Typography
enum UltraTypography {
    // Display - Hero text
    static let hero = Font.system(size: scaled(48), weight: .black, design: .rounded)
    static let display = Font.system(size: scaled(40), weight: .bold, design: .rounded)

    // Titles
    static let title1 = Font.system(size: scaled(32), weight: .bold, design: .rounded)
    static let title2 = Font.system(size: scaled(26), weight: .bold, design: .rounded)
    static let title3 = Font.system(size: scaled(22), weight: .semibold, design: .rounded)

    // Body
    static let headline = Font.system(size: scaled(18), weight: .semibold, design: .rounded)
    static let body = Font.system(size: scaled(17), weight: .regular, design: .rounded)
    static let bodyBold = Font.system(size: scaled(17), weight: .semibold, design: .rounded)
    static let callout = Font.system(size: scaled(16), weight: .medium, design: .rounded)

    // Small text
    static let subheadline = Font.system(size: scaled(15), weight: .medium, design: .rounded)
    static let footnote = Font.system(size: scaled(13), weight: .regular, design: .rounded)
    static let caption = Font.system(size: scaled(12), weight: .medium, design: .rounded)
    static let micro = Font.system(size: scaled(10), weight: .semibold, design: .rounded)

    // Special
    static let stat = Font.system(size: scaled(36), weight: .black, design: .rounded)
    static let timer = Font.system(size: scaled(56), weight: .bold, design: .monospaced)
    static let emoji = Font.system(size: scaled(28))
    static let emojiLarge = Font.system(size: scaled(48))
    static let emojiGiant = Font.system(size: scaled(80))

    private static func scaled(_ size: CGFloat) -> CGFloat {
        size * DeviceSize.current.scale
    }
}

// MARK: - Ultra Spacing (8pt Grid)
enum UltraSpacing {
    static let xxxs: CGFloat = scaled(2)
    static let xxs: CGFloat = scaled(4)
    static let xs: CGFloat = scaled(8)
    static let sm: CGFloat = scaled(12)
    static let md: CGFloat = scaled(16)
    static let lg: CGFloat = scaled(24)
    static let xl: CGFloat = scaled(32)
    static let xxl: CGFloat = scaled(48)
    static let xxxl: CGFloat = scaled(64)

    // Screen padding
    static let screenH: CGFloat = DeviceSize.current == .tablet ? 32 : 20
    static let screenV: CGFloat = DeviceSize.current == .tablet ? 24 : 16
    static let screenPadding: CGFloat = DeviceSize.current == .tablet ? 32 : 20

    // Card padding
    static let cardPadding: CGFloat = scaled(20)

    private static func scaled(_ size: CGFloat) -> CGFloat {
        size * (DeviceSize.current == .tablet ? 1.2 : 1.0)
    }
}

// MARK: - Ultra Radius
enum UltraRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 36
    static let pill: CGFloat = 9999
    static let full: CGFloat = 9999  // Alias for pill
}

// MARK: - Holographic Card
/// Premium card with animated holographic border
struct HolographicCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = UltraSpacing.cardPadding
    var cornerRadius: CGFloat = UltraRadius.xl
    var showHoloBorder: Bool = true
    var intensity: Double = 0.7

    @State private var gradientRotation: Double = 0

    init(
        padding: CGFloat = UltraSpacing.cardPadding,
        cornerRadius: CGFloat = UltraRadius.xl,
        showHoloBorder: Bool = true,
        intensity: Double = 0.7,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.showHoloBorder = showHoloBorder
        self.intensity = intensity
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Deep glass base
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)

                    // Inner depth gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.black.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Holographic border
                    if showHoloBorder {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        UltraColors.plasmaPin,
                                        UltraColors.fireOrange,
                                        UltraColors.sunburstGold,
                                        UltraColors.neonMint,
                                        UltraColors.laserBlue,
                                        UltraColors.cyberViolet,
                                        UltraColors.plasmaPin
                                    ],
                                    center: .center,
                                    angle: .degrees(gradientRotation)
                                ),
                                lineWidth: 2
                            )
                            .opacity(intensity)
                    }
                }
            )
            .shadow(color: UltraColors.cyberViolet.opacity(0.25), radius: 24, y: 12)
            .shadow(color: UltraColors.plasmaPin.opacity(0.15), radius: 48, y: 24)
            .onAppear {
                if showHoloBorder {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        gradientRotation = 360
                    }
                }
            }
    }
}

// MARK: - Ultra Button
/// Premium 3D button with shimmer effect
struct UltraButton: View {
    let emoji: String
    let label: String
    let action: () -> Void
    var style: UltraButtonStyle = .primary
    var size: UltraButtonSize = .large
    var isLoading: Bool = false

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200

    enum UltraButtonStyle {
        case primary    // Hot pink → purple
        case secondary  // Blue → purple
        case success    // Mint
        case gold       // VIP gold
        case glass      // Transparent glass
        case danger     // Red
    }

    enum UltraButtonSize {
        case small, medium, large, xlarge

        var height: CGFloat {
            switch self {
            case .small: return 44
            case .medium: return 52
            case .large: return 60
            case .xlarge: return 72
            }
        }

        var emojiSize: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 26
            case .large: return 32
            case .xlarge: return 40
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 15
            case .medium: return 17
            case .large: return 19
            case .xlarge: return 22
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 28
            case .large: return 36
            case .xlarge: return 44
            }
        }
    }

    var body: some View {
        Button {
            NightOutHaptics.medium()
            action()
        } label: {
            HStack(spacing: UltraSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(emoji)
                        .font(.system(size: size.emojiSize))

                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: size.height)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Base gradient
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .fill(gradientForStyle)

                    // 3D top highlight
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(2)

                    // Shimmer effect
                    if style != .glass {
                        RoundedRectangle(cornerRadius: UltraRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: UltraRadius.lg))
                    }

                    // Border highlight
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: shadowColorForStyle.opacity(isPressed ? 0.3 : 0.6), radius: isPressed ? 8 : 20, y: isPressed ? 4 : 10)
            .shadow(color: shadowColorForStyle.opacity(0.3), radius: isPressed ? 4 : 10, y: isPressed ? 2 : 5)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: UltraRadius.lg))
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
        .disabled(isLoading)
    }

    private var gradientForStyle: LinearGradient {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [UltraColors.plasmaPin, UltraColors.cyberViolet],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return LinearGradient(
                colors: [UltraColors.laserBlue, UltraColors.cyberViolet],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [UltraColors.neonMint, UltraColors.laserBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [UltraColors.sunburstGold, UltraColors.fireOrange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .glass:
            return LinearGradient(
                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .danger:
            return LinearGradient(
                colors: [UltraColors.liveRed, UltraColors.plasmaPin],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var shadowColorForStyle: Color {
        switch style {
        case .primary: return UltraColors.plasmaPin
        case .secondary: return UltraColors.laserBlue
        case .success: return UltraColors.neonMint
        case .gold: return UltraColors.sunburstGold
        case .glass: return Color.white
        case .danger: return UltraColors.liveRed
        }
    }
}

// MARK: - Ultra Input Field
struct UltraInputField: View {
    let emoji: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @FocusState private var isFocused: Bool
    @State private var borderRotation: Double = 0

    var body: some View {
        HStack(spacing: UltraSpacing.sm) {
            Text(emoji)
                .font(.system(size: 24))

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(UltraTypography.body)
            .foregroundColor(UltraColors.titanium)
            .focused($isFocused)
        }
        .padding(.horizontal, UltraSpacing.lg)
        .padding(.vertical, UltraSpacing.md + 4)
        .background(
            ZStack {
                // Inset background
                RoundedRectangle(cornerRadius: UltraRadius.lg)
                    .fill(Color.black.opacity(0.4))

                // Inner shadow
                RoundedRectangle(cornerRadius: UltraRadius.lg)
                    .stroke(Color.black.opacity(0.6), lineWidth: 3)
                    .blur(radius: 3)
                    .offset(y: 2)
                    .mask(RoundedRectangle(cornerRadius: UltraRadius.lg).fill(.black))

                // Focus border - holographic when focused
                if isFocused {
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    UltraColors.plasmaPin,
                                    UltraColors.cyberViolet,
                                    UltraColors.laserBlue,
                                    UltraColors.plasmaPin
                                ],
                                center: .center,
                                angle: .degrees(borderRotation)
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
            }
        )
        .shadow(color: isFocused ? UltraColors.plasmaPin.opacity(0.4) : .clear, radius: 12)
        .animation(.easeInOut(duration: 0.25), value: isFocused)
        .onChange(of: isFocused) { _, focused in
            if focused {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    borderRotation = 360
                }
            }
        }
    }
}

// MARK: - Animated Disco Ball
struct AnimatedDiscoBall: View {
    var size: CGFloat = 120
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var sparklePhase: Double = 0

    var body: some View {
        ZStack {
            // Outer glow rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                UltraColors.plasmaPin.opacity(0.4),
                                UltraColors.cyberViolet.opacity(0.3),
                                UltraColors.laserBlue.opacity(0.4),
                                UltraColors.plasmaPin.opacity(0.4)
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size + CGFloat(i * 30), height: size + CGFloat(i * 30))
                    .opacity(0.5 - Double(i) * 0.15)
                    .scaleEffect(pulseScale + CGFloat(i) * 0.05)
                    .rotationEffect(.degrees(rotation + Double(i * 30)))
            }

            // Core glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            UltraColors.plasmaPin.opacity(0.5),
                            UltraColors.cyberViolet.opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 20)

            // Disco ball
            Text("🪩")
                .font(.system(size: size * 0.8))
                .rotationEffect(.degrees(rotation * 0.5))
                .shadow(color: .white.opacity(0.6), radius: 12)
                .shadow(color: UltraColors.plasmaPin.opacity(0.5), radius: 24)

            // Sparkle particles
            ForEach(0..<8, id: \.self) { i in
                SparkleParticle(size: size * 0.12)
                    .offset(
                        x: cos(sparklePhase + Double(i) * .pi / 4) * size * 0.65,
                        y: sin(sparklePhase + Double(i) * .pi / 4) * size * 0.65
                    )
                    .opacity(sin(sparklePhase + Double(i)) * 0.5 + 0.5)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                sparklePhase = .pi * 2
            }
        }
    }
}

// MARK: - Sparkle Particle
struct SparkleParticle: View {
    var size: CGFloat = 14
    @State private var twinkle: Bool = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, UltraColors.sunburstGold],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scaleEffect(twinkle ? 1.3 : 0.7)
            .opacity(twinkle ? 1 : 0.5)
            .blur(radius: twinkle ? 0 : 1)
            .shadow(color: .white, radius: 6)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.5...1.2))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...0.5))
                ) {
                    twinkle = true
                }
            }
    }
}

// MARK: - Gradient Logo Text
struct GradientLogoText: View {
    let text: String
    var fontSize: CGFloat = 48
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        ZStack {
            // Shadow layer
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(UltraColors.cyberViolet.opacity(0.5))
                .blur(radius: 8)
                .offset(y: 4)

            // Main text with animated gradient
            Text(text)
                .font(.system(size: fontSize, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            UltraColors.plasmaPin,
                            UltraColors.cyberViolet,
                            UltraColors.laserBlue,
                            UltraColors.neonMint,
                            UltraColors.plasmaPin
                        ],
                        startPoint: UnitPoint(x: shimmerOffset, y: 0),
                        endPoint: UnitPoint(x: shimmerOffset + 1, y: 1)
                    )
                )
                .shadow(color: UltraColors.plasmaPin.opacity(0.6), radius: 12)
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                shimmerOffset = 2
            }
        }
    }
}

// MARK: - Ultra Stat Card
struct UltraStatCard: View {
    let emoji: String
    let value: String
    let label: String
    var accentColor: Color = UltraColors.plasmaPin

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: UltraSpacing.xs) {
            Text(emoji)
                .font(.system(size: 32))
                .scaleEffect(hasAppeared ? 1 : 0.5)

            Text(value)
                .font(UltraTypography.stat)
                .foregroundStyle(UltraColors.titanium)
                .contentTransition(.numericText())

            Text(label)
                .font(UltraTypography.caption)
                .foregroundStyle(UltraColors.silver)
                .textCase(.uppercase)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, UltraSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: UltraRadius.lg)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: UltraRadius.lg)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: accentColor.opacity(0.2), radius: 16)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
}

// MARK: - Cinematic Night Card
struct CinematicNightCard: View {
    let night: SupabaseNight
    @State private var hasAppeared = false
    @State private var holoRotation: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UltraSpacing.md) {
            // Header
            HStack {
                // Avatar with live indicator
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(UltraColors.primaryGradient)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text("?")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )

                    if night.isActive {
                        UltraLiveIndicator(size: 12)
                            .offset(x: 4, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(night.title ?? "Night Out")
                        .font(UltraTypography.headline)
                        .foregroundStyle(UltraColors.titanium)

                    HStack(spacing: 6) {
                        if let venueName = night.currentVenueName {
                            Text("📍 \(venueName)")
                                .font(UltraTypography.caption)
                                .foregroundStyle(UltraColors.silver)
                        }

                        Text("•")
                            .foregroundStyle(UltraColors.slate)

                        Text(timeAgo(night.startTime))
                            .font(UltraTypography.caption)
                            .foregroundStyle(UltraColors.slate)
                    }
                }

                Spacer()

                if night.isActive {
                    Text("LIVE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(UltraColors.liveRed)
                        )
                        .shadow(color: UltraColors.liveRed.opacity(0.5), radius: 8)
                }
            }

            // Title
            if let title = night.title, !title.isEmpty {
                Text(title)
                    .font(UltraTypography.bodyBold)
                    .foregroundStyle(UltraColors.titanium)
            }

            // Stats row
            HStack(spacing: UltraSpacing.md) {
                UltraStatPill(emoji: "🍺", value: "0") // SupabaseNight doesn't have drinks relationship
                UltraStatPill(emoji: "📸", value: "0") // SupabaseNight doesn't have media relationship
                UltraStatPill(emoji: "📍", value: "0") // SupabaseNight doesn't have venues relationship

                if let duration = night.duration {
                    UltraStatPill(emoji: "⏱️", value: formatDuration(duration))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(UltraColors.plasmaPin)
                    Text("\(night.likeCount ?? 0)")
                        .font(UltraTypography.caption)
                        .foregroundStyle(UltraColors.silver)
                }
            }
        }
        .padding(UltraSpacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: UltraRadius.xl)
                    .fill(.ultraThinMaterial)

                // Holographic border
                RoundedRectangle(cornerRadius: UltraRadius.xl)
                    .stroke(
                        AngularGradient(
                            colors: [
                                UltraColors.plasmaPin.opacity(0.5),
                                UltraColors.cyberViolet.opacity(0.3),
                                UltraColors.laserBlue.opacity(0.5),
                                UltraColors.plasmaPin.opacity(0.5)
                            ],
                            center: .center,
                            angle: .degrees(holoRotation)
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: UltraColors.cyberViolet.opacity(0.2), radius: 20, y: 10)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                hasAppeared = true
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                holoRotation = 360
            }
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Ultra Stat Pill
struct UltraStatPill: View {
    let emoji: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 14))
            Text(value)
                .font(UltraTypography.caption)
                .foregroundStyle(UltraColors.titanium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
        )
    }
}

// MARK: - Ultra Live Indicator
struct UltraLiveIndicator: View {
    var size: CGFloat = 10
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(UltraColors.liveRed)
                .frame(width: size * 3, height: size * 3)
                .scaleEffect(isPulsing ? 2 : 1)
                .opacity(isPulsing ? 0 : 0.5)

            // Middle glow
            Circle()
                .fill(UltraColors.liveRed)
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 4)

            // Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, UltraColors.liveRed],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Aurora Background
struct AuroraBackground: View {
    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            UltraColors.void

            // Aurora waves
            ForEach(0..<3, id: \.self) { i in
                AuroraWave(
                    color: [UltraColors.cyberViolet, UltraColors.plasmaPin, UltraColors.laserBlue][i],
                    phase: phase + Double(i) * 0.5,
                    amplitude: 50 + CGFloat(i) * 30
                )
                .opacity(0.3 - Double(i) * 0.08)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct AuroraWave: View {
    let color: Color
    let phase: Double
    let amplitude: CGFloat

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                let midY = height * 0.4

                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0, to: width, by: 5) {
                    let relativeX = CGFloat(x) / width
                    let piValue: CGFloat = .pi
                    let y = midY + sin(relativeX * piValue * 2 + phase) * amplitude
                    path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                }

                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: 30)
        }
    }
}

// MARK: - Particle Confetti
struct ParticleConfetti: View {
    @State private var particles: [ParticleData] = []
    let emojis = ["🎉", "🎊", "🥳", "✨", "🪩", "🍾", "💫", "⭐", "🔥", "💖"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .scaleEffect(particle.scale)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        for _ in 0..<50 {
            let particle = ParticleData(
                emoji: emojis.randomElement()!,
                size: CGFloat.random(in: 24...48),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -60
                ),
                opacity: 1.0,
                rotation: 0,
                scale: 1.0
            )
            particles.append(particle)
        }

        for index in particles.indices {
            let delay = Double.random(in: 0...1.5)
            let duration = Double.random(in: 2.5...4.5)

            withAnimation(.easeIn(duration: duration).delay(delay)) {
                particles[index].position.y = size.height + 100
                particles[index].position.x += CGFloat.random(in: -100...100)
                particles[index].rotation = Double.random(in: -720...720)
                particles[index].opacity = 0
                particles[index].scale = 0.3
            }
        }
    }
}

struct ParticleData: Identifiable {
    let id = UUID()
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    var rotation: Double
    var scale: CGFloat
}

// MARK: - View Extensions
extension View {
    func ultraBackground() -> some View {
        self.background(AuroraBackground())
    }

    func holographicGlow(color: Color = UltraColors.plasmaPin, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 2)
    }

    func ultraAppear(delay: Double = 0) -> some View {
        self.modifier(UltraAppearModifier(delay: delay))
    }

    func staggeredAppear(index: Int, baseDelay: Double = 0.08) -> some View {
        self.modifier(StaggeredAppearModifier(index: index, baseDelay: baseDelay))
    }
}

struct UltraAppearModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 30)
            .scaleEffect(hasAppeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 25)
            .scaleEffect(hasAppeared ? 1 : 0.96)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(index) * baseDelay)) {
                    hasAppeared = true
                }
            }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 40) {
            AnimatedDiscoBall(size: 140)

            GradientLogoText(text: "NIGHTOUT", fontSize: 52)

            UltraButton(emoji: "🎉", label: "Let's Party!", action: {})

            UltraButton(emoji: "✨", label: "Magic Link", action: {}, style: .glass)

            UltraInputField(emoji: "📧", placeholder: "Email", text: .constant(""))

            HStack(spacing: 16) {
                UltraStatCard(emoji: "🌙", value: "42", label: "Nights")
                UltraStatCard(emoji: "🍺", value: "186", label: "Drinks", accentColor: UltraColors.sunburstGold)
            }

            HolographicCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("@party_queen")
                            .font(UltraTypography.headline)
                            .foregroundStyle(UltraColors.titanium)
                        Spacer()
                        UltraLiveIndicator()
                        Text("LIVE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(UltraColors.liveRed)
                    }

                    Text("Best night of my life! 🔥🪩✨")
                        .foregroundStyle(UltraColors.silver)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 60)
    }
    .ultraBackground()
}
